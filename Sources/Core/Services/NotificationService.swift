import Foundation
import UserNotifications

/// Protocol defining notification management operations
public protocol NotificationServiceProtocol {
    /// Request notification permissions from the user
    func requestNotificationPermissions() async throws -> Bool
    
    /// Schedule a notification for a reminder
    func scheduleReminderNotification(for reminder: Reminder) async throws
    
    /// Cancel a notification for a reminder
    func cancelReminderNotification(for reminder: Reminder) async
    
    /// Cancel all scheduled notifications
    func cancelAllNotifications() async
}

/// Service responsible for managing local notifications
public final class NotificationService: NotificationServiceProtocol {
    private let notificationCenter: UNUserNotificationCenter
    
    public init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }
    
    public func requestNotificationPermissions() async throws -> Bool {
        do {
            let settings = await notificationCenter.notificationSettings()
            
            if settings.authorizationStatus == .notDetermined {
                return try await notificationCenter.requestAuthorization(options: [.alert, .sound])
            }
            
            return settings.authorizationStatus == .authorized
        } catch {
            throw ServiceError.notificationPermissionDenied
        }
    }
    
    public func scheduleReminderNotification(for reminder: Reminder) async throws {
        // Check if notifications are authorized
        let settings = await notificationCenter.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            throw ServiceError.notificationPermissionDenied
        }
        
        // Cancel any existing notification for this reminder
        await cancelReminderNotification(for: reminder)
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        if let notes = reminder.notes {
            content.body = notes
        }
        content.sound = .default
        
        // Add priority to the notification
        switch reminder.priority {
        case .high:
            content.title = "❗️ " + content.title
        case .medium:
            content.title = "⚡️ " + content.title
        case .low:
            content.title = "📝 " + content.title
        }
        
        // Create trigger
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await notificationCenter.add(request)
        } catch {
            throw ServiceError.notificationSchedulingFailed
        }
    }
    
    public func cancelReminderNotification(for reminder: Reminder) async {
        await notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [reminder.id.uuidString]
        )
    }
    
    public func cancelAllNotifications() async {
        await notificationCenter.removeAllPendingNotificationRequests()
    }
} 