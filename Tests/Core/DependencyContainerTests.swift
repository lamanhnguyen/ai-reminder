import XCTest
@testable import VoiceReminders
import Combine

final class DependencyContainerTests: XCTestCase {
    var container: DependencyContainer!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        container = DependencyContainer()
        cancellables = []
    }
    
    override func tearDown() async throws {
        container = nil
        cancellables = nil
        try await super.tearDown()
    }
    
    // MARK: - Service Initialization Tests
    
    func testServicesAreInitializedLazily() async throws {
        // Access services and verify they're initialized only when first accessed
        XCTAssertNotNil(container.remindersService)
        XCTAssertNotNil(container.coreDataService)
        XCTAssertNotNil(container.voiceRecognitionService)
        XCTAssertNotNil(container.notificationService)
    }
    
    func testServiceDependenciesAreInjectedCorrectly() async throws {
        // Verify that services have their dependencies properly injected
        let remindersService = container.remindersService
        let coreDataService = container.coreDataService
        let notificationService = container.notificationService
        
        // Create a test reminder
        let reminder = Reminder(title: "Test Reminder",
                              notes: "Test Notes",
                              dueDate: Date(),
                              priority: .medium)
        
        // Test reminder creation flow through services
        let createdReminder = try await remindersService.createReminder(reminder)
        XCTAssertNotNil(createdReminder)
        
        // Verify the reminder was persisted in Core Data
        let fetchedReminders = try await remindersService.fetchReminders()
        XCTAssertEqual(fetchedReminders.count, 1)
        XCTAssertEqual(fetchedReminders.first?.id, createdReminder.id)
    }
    
    // MARK: - Testing Support Tests
    
    func testCreateForTestingWithMockServices() async throws {
        // Create a container with mock services
        let testContainer = DependencyContainer.createForTesting(
            remindersService: MockRemindersService(),
            coreDataService: MockCoreDataService(),
            voiceRecognitionService: MockVoiceRecognitionService(),
            notificationService: MockNotificationService()
        )
        
        // Verify mock services are used
        XCTAssertTrue(testContainer.remindersService is MockRemindersService)
        XCTAssertTrue(testContainer.coreDataService is MockCoreDataService)
        XCTAssertTrue(testContainer.voiceRecognitionService is MockVoiceRecognitionService)
        XCTAssertTrue(testContainer.notificationService is MockNotificationService)
    }
    
    // MARK: - State Management Tests
    
    func testInitializationState() async throws {
        // Test initialization state of services
        let expectation = XCTestExpectation(description: "Services initialized")
        
        // Request authorization for required services
        let notificationAuth = try await container.notificationService.requestAuthorization()
        let voiceAuth = await container.voiceRecognitionService.requestAuthorization()
        
        XCTAssertTrue(notificationAuth)
        XCTAssertTrue(voiceAuth)
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testReset() async throws {
        // Add some test data
        let reminder = Reminder(title: "Test Reminder",
                              notes: "Test Notes",
                              dueDate: Date(),
                              priority: .medium)
        
        _ = try await container.remindersService.createReminder(reminder)
        
        // Reset the container
        container.reset()
        
        // Verify services are reinitialized
        let newRemindersService = container.remindersService
        let fetchedReminders = try await newRemindersService.fetchReminders()
        XCTAssertEqual(fetchedReminders.count, 0)
    }
}

// MARK: - Mock Services

private class MockRemindersService: RemindersServiceProtocol {
    var reminders: [Reminder] = []
    var remindersPublisher = CurrentValueSubject<[Reminder], Never>([])
    
    func createReminder(_ reminder: Reminder) async throws -> Reminder {
        reminders.append(reminder)
        remindersPublisher.send(reminders)
        return reminder
    }
    
    func updateReminder(_ reminder: Reminder) async throws -> Reminder {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            remindersPublisher.send(reminders)
            return reminder
        }
        throw ReminderError.notFound
    }
    
    func deleteReminder(_ reminder: Reminder) async throws {
        reminders.removeAll { $0.id == reminder.id }
        remindersPublisher.send(reminders)
    }
    
    func fetchReminders() async throws -> [Reminder] {
        return reminders
    }
    
    func toggleReminderCompletion(_ reminder: Reminder) async throws -> Reminder {
        var updatedReminder = reminder
        updatedReminder.isCompleted.toggle()
        return try await updateReminder(updatedReminder)
    }
}

private class MockCoreDataService: CoreDataServiceProtocol {
    var persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext
    var remindersPublisher = CurrentValueSubject<[ReminderEntity], Never>([])
    
    init() {
        let container = NSPersistentContainer(name: "VoiceReminders")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        self.persistentContainer = container
        self.viewContext = container.viewContext
    }
    
    func saveContext() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
    
    func createBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    func delete(_ object: NSManagedObject) throws {
        viewContext.delete(object)
        try saveContext()
    }
}

private class MockVoiceRecognitionService: VoiceRecognitionServiceProtocol {
    var isRecording = false
    var transcriptionPublisher = PassthroughSubject<String, Error>()
    
    func startRecording() async throws {
        isRecording = true
    }
    
    func stopRecording() async {
        isRecording = false
    }
    
    func requestAuthorization() async -> Bool {
        return true
    }
}

private class MockNotificationService: NotificationServiceProtocol {
    var scheduledNotifications: [Reminder: UNNotificationRequest] = [:]
    
    func scheduleNotification(for reminder: Reminder) async throws {
        let request = UNNotificationRequest(identifier: reminder.id.uuidString,
                                         content: UNNotificationContent(),
                                         trigger: nil)
        scheduledNotifications[reminder] = request
    }
    
    func cancelNotification(for reminder: Reminder) async {
        scheduledNotifications.removeValue(forKey: reminder)
    }
    
    func requestAuthorization() async throws -> Bool {
        return true
    }
} 