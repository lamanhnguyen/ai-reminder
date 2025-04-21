import Foundation
import UserNotifications

protocol NotificationServicing {
    func requestPermissions() async throws
    func scheduleNotification(for reminder: Reminder) async throws
    func cancelNotification(for reminder: Reminder) async throws
    func cancelAllNotifications() async throws
} 