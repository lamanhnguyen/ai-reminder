import Foundation

protocol RemindersServicing {
    func createReminder(title: String, content: String?, dueDate: Date?) async throws -> Reminder
    func fetchReminders() async throws -> [Reminder]
    func updateReminder(_ reminder: Reminder) async throws
    func deleteReminder(_ reminder: Reminder) async throws
    func markReminderComplete(_ reminder: Reminder, isComplete: Bool) async throws
} 