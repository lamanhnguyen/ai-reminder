import Foundation
import CoreData
import Combine

/// Protocol defining the Core Data service operations
protocol CoreDataServiceProtocol {
    /// The main view context for Core Data operations
    var viewContext: NSManagedObjectContext { get }
    
    /// Save changes in the view context
    func saveContext() throws
    
    /// Create a new background context for performing operations
    func newBackgroundContext() -> NSManagedObjectContext
    
    /// Perform a fetch request and return the results
    func fetch<T>(_ request: NSFetchRequest<T>) throws -> [T] where T: NSFetchRequestResult
    
    /// Delete an object from Core Data
    func delete(_ object: NSManagedObject) throws
    
    /// Delete multiple objects from Core Data
    func delete(_ objects: [NSManagedObject]) throws
    
    /// Publisher for changes in a specific entity type
    func publisher<T: NSManagedObject>(for entityName: String) -> AnyPublisher<[T], Error>
    
    var remindersPublisher: AnyPublisher<[Reminder], Error> { get }
    func createReminder(_ reminder: Reminder) async throws
    func updateReminder(_ reminder: Reminder) async throws
    func deleteReminder(_ reminder: Reminder) async throws
    func deleteAllReminders() async throws
    func fetchReminders() async throws -> [Reminder]
}

/// Core Data service implementation
final class CoreDataService: CoreDataServiceProtocol {
    /// Persistent container for Core Data
    private let container: NSPersistentContainer
    private let remindersSubject = CurrentValueSubject<[Reminder], Never>([])
    
    /// Main view context for Core Data operations
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    /// Initialize the Core Data service
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "VoiceReminders")
        
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
        // Configure the view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    /// Save changes in the view context
    func saveContext() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
    
    /// Create a new background context
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    /// Perform a fetch request
    func fetch<T>(_ request: NSFetchRequest<T>) throws -> [T] where T: NSFetchRequestResult {
        try viewContext.fetch(request)
    }
    
    /// Delete an object
    func delete(_ object: NSManagedObject) throws {
        viewContext.delete(object)
        try saveContext()
    }
    
    /// Delete multiple objects
    func delete(_ objects: [NSManagedObject]) throws {
        objects.forEach { viewContext.delete($0) }
        try saveContext()
    }
    
    /// Publisher for entity changes
    func publisher<T: NSManagedObject>(for entityName: String) -> AnyPublisher<[T], Error> {
        let request = NSFetchRequest<T>(entityName: entityName)
        
        return NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: viewContext)
            .tryMap { [weak self] _ -> [T] in
                guard let self = self else { throw ServiceError.serviceUnavailable }
                return try self.fetch(request)
            }
            .eraseToAnyPublisher()
    }
    
    var remindersPublisher: AnyPublisher<[Reminder], Error> {
        remindersSubject.eraseToAnyPublisher()
    }
    
    private func performBackgroundTask<T>(_ task: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await container.performBackgroundTask { context in
            let result = try task(context)
            try context.save()
            return result
        }
    }
    
    func createReminder(_ reminder: Reminder) async throws {
        try await performBackgroundTask { context in
            _ = ReminderEntity.fromDomain(reminder, context: context)
        }
        try await refreshReminders()
    }
    
    func updateReminder(_ reminder: Reminder) async throws {
        try await performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<ReminderEntity> = ReminderEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", reminder.id)
            
            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.entityNotFound
            }
            
            entity.update(from: reminder)
        }
        try await refreshReminders()
    }
    
    func deleteReminder(_ reminder: Reminder) async throws {
        try await performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<ReminderEntity> = ReminderEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", reminder.id)
            
            guard let entity = try context.fetch(fetchRequest).first else {
                throw PersistenceError.entityNotFound
            }
            
            context.delete(entity)
        }
        try await refreshReminders()
    }
    
    func deleteAllReminders() async throws {
        try await performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ReminderEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs
            
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []
            ]
            
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
        }
        try await refreshReminders()
    }
    
    func fetchReminders() async throws -> [Reminder] {
        try await performBackgroundTask { context in
            let fetchRequest: NSFetchRequest<ReminderEntity> = ReminderEntity.fetchRequest()
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(keyPath: \ReminderEntity.dueDate, ascending: true),
                NSSortDescriptor(keyPath: \ReminderEntity.priority, ascending: false),
                NSSortDescriptor(keyPath: \ReminderEntity.createdAt, ascending: false)
            ]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomain() }
        }
    }
    
    private func refreshReminders() async throws {
        let reminders = try await fetchReminders()
        remindersSubject.send(reminders)
    }
}

// MARK: - Error Handling
extension CoreDataService {
    /// Core Data specific errors
    enum CoreDataError: LocalizedError {
        case failedToSave
        case failedToFetch
        case failedToDelete
        case invalidEntity
        
        var errorDescription: String? {
            switch self {
            case .failedToSave:
                return "Failed to save Core Data changes"
            case .failedToFetch:
                return "Failed to fetch data"
            case .failedToDelete:
                return "Failed to delete data"
            case .invalidEntity:
                return "Invalid Core Data entity"
            }
        }
    }
} 