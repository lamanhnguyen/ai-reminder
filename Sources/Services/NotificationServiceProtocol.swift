import Foundation
import UserNotifications

protocol NotificationServiceProtocol {
    /// The current authorization status for notifications
    var authorizationStatus: UNAuthorizationStatus { get async }
    
    /// Request authorization for sending notifications
    /// - Parameter options: The types of notifications to request authorization for
    /// - Returns: Whether authorization was granted
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    
    /// Schedule a notification for a reminder
    /// - Parameter reminder: The reminder to schedule a notification for
    func scheduleNotification(for reminder: Reminder) async throws
    
    /// Cancel all pending notifications for a reminder
    /// - Parameter reminder: The reminder to cancel notifications for
    func cancelNotifications(for reminder: Reminder) async
    
    /// Cancel all pending notifications
    func cancelAllNotifications() async
    
    /// Get all pending notification requests
    /// - Returns: Array of pending notification requests
    func getPendingNotificationRequests() async -> [UNNotificationRequest]
} 