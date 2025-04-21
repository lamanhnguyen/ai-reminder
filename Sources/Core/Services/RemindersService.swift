import Foundation
import CoreData
import Combine

/// Protocol defining the operations available for managing reminders
protocol RemindersServiceProtocol {
    /// Publisher that emits the current list of reminders
    var remindersPublisher: AnyPublisher<[Reminder], Error> { get }
    
    /// Create a new reminder
    func createReminder(_ reminder: Reminder) async throws
    
    /// Update an existing reminder
    func updateReminder(_ reminder: Reminder) async throws
    
    /// Delete a specific reminder
    func deleteReminder(_ reminder: Reminder) async throws
    
    /// Delete all reminders
    func deleteAllReminders() async throws
    
    /// Toggle the completion status of a reminder
    func toggleReminderCompletion(_ reminder: Reminder) async throws
    
    /// Fetch all reminders
    func fetchReminders() async throws -> [Reminder]
}

/// Service responsible for managing reminders, coordinating between persistence and notifications
final class RemindersService: RemindersServiceProtocol {
    private let coreDataService: CoreDataServiceProtocol
    private let notificationService: NotificationServiceProtocol
    
    init(coreDataService: CoreDataServiceProtocol, notificationService: NotificationServiceProtocol) {
        self.coreDataService = coreDataService
        self.notificationService = notificationService
    }
    
    var remindersPublisher: AnyPublisher<[Reminder], Error> {
        coreDataService.remindersPublisher
    }
    
    func createReminder(_ reminder: Reminder) async throws {
        // Create the reminder in CoreData
        try await coreDataService.createReminder(reminder)
        
        // Schedule a notification if the reminder has a due date
        if let dueDate = reminder.dueDate {
            try await notificationService.scheduleReminderNotification(for: reminder)
        }
    }
    
    func updateReminder(_ reminder: Reminder) async throws {
        // Update the reminder in CoreData
        try await coreDataService.updateReminder(reminder)
        
        // Cancel existing notification and schedule a new one if needed
        try await notificationService.cancelReminderNotification(for: reminder)
        if let dueDate = reminder.dueDate, !reminder.isCompleted {
            try await notificationService.scheduleReminderNotification(for: reminder)
        }
    }
    
    func deleteReminder(_ reminder: Reminder) async throws {
        // Cancel any scheduled notification for this reminder
        try await notificationService.cancelReminderNotification(for: reminder)
        
        // Delete the reminder from CoreData
        try await coreDataService.deleteReminder(reminder)
    }
    
    func deleteAllReminders() async throws {
        // Cancel all scheduled notifications
        try await notificationService.cancelAllNotifications()
        
        // Delete all reminders from CoreData
        try await coreDataService.deleteAllReminders()
    }
    
    func toggleReminderCompletion(_ reminder: Reminder) async throws {
        var updatedReminder = reminder
        updatedReminder.isCompleted.toggle()
        updatedReminder.updatedAt = Date()
        
        // Update the reminder in CoreData
        try await coreDataService.updateReminder(updatedReminder)
        
        // Handle notification based on completion status
        if updatedReminder.isCompleted {
            try await notificationService.cancelReminderNotification(for: updatedReminder)
        } else if let dueDate = updatedReminder.dueDate, dueDate > Date() {
            try await notificationService.scheduleReminderNotification(for: updatedReminder)
        }
    }
    
    func fetchReminders() async throws -> [Reminder] {
        try await coreDataService.fetchReminders()
    }
}

// MARK: - Error Handling
extension RemindersService {
    enum RemindersServiceError: LocalizedError {
        case invalidReminder
        case reminderNotFound
        case failedToScheduleNotification
        case failedToUpdateReminder
        
        var errorDescription: String? {
            switch self {
            case .invalidReminder:
                return "The reminder is invalid or missing required fields"
            case .reminderNotFound:
                return "The specified reminder could not be found"
            case .failedToScheduleNotification:
                return "Failed to schedule notification for the reminder"
            case .failedToUpdateReminder:
                return "Failed to update the reminder"
            }
        }
    }
}

// MARK: - ReminderEntity Extension
private extension ReminderEntity {
    func toDomainModel() -> Reminder {
        Reminder(
            id: id ?? UUID(),
            title: title ?? "",
            notes: notes,
            dueDate: dueDate ?? Date(),
            priority: ReminderPriority(rawValue: Int(priority)) ?? .medium,
            isCompleted: isCompleted
        )
    }
} 