import Foundation

enum ReminderPriority: Int, Codable {
    case low = 0
    case medium = 1
    case high = 2
}

struct Reminder: Identifiable, Codable {
    let id: UUID
    var title: String
    var notes: String?
    var dueDate: Date
    var priority: ReminderPriority
    var isCompleted: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date,
        priority: ReminderPriority = .medium,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
    }
}

// MARK: - Equatable
extension Reminder: Equatable {
    static func == (lhs: Reminder, rhs: Reminder) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Reminder: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 