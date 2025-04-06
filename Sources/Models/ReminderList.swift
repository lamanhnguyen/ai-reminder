import Foundation

struct ReminderList: Identifiable, Codable {
    let id: UUID
    var name: String
    var color: String // Store as hex string
    var reminders: [Reminder]
    
    init(id: UUID = UUID(), name: String, color: String = "#FF6B6B", reminders: [Reminder] = []) {
        self.id = id
        self.name = name
        self.color = color
        self.reminders = reminders
    }
} 