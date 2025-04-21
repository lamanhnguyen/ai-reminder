import Foundation

/// Priority levels for reminders
enum ReminderPriority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    
    var priorityLevel: Int {
        switch self {
        case .low: return 5
        case .medium: return 3
        case .high: return 1
        }
    }
}

/// Frequency options for recurring reminders
enum RecurrenceFrequency: String, CaseIterable, Codable {
    case daily
    case weekly
    case biweekly
    case monthly
    case yearly
}

/// A reminder representing a task or event
struct Reminder: Identifiable, Codable {
    let id: UUID
    var title: String
    var notes: String?
    var dueDate: Date
    var endDate: Date?
    var isCompleted: Bool
    var priority: ReminderPriority
    var isRecurring: Bool
    var recurrenceFrequency: RecurrenceFrequency?
    var plannedStartDate: Date?
    var plannedEndDate: Date?
    var listId: UUID?
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date,
        endDate: Date? = nil,
        isCompleted: Bool = false,
        priority: ReminderPriority = .medium,
        isRecurring: Bool = false,
        recurrenceFrequency: RecurrenceFrequency? = nil,
        plannedStartDate: Date? = nil,
        plannedEndDate: Date? = nil,
        listId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.endDate = endDate ?? dueDate.addingTimeInterval(3600)
        self.isCompleted = isCompleted
        self.priority = priority
        self.isRecurring = isRecurring
        self.recurrenceFrequency = recurrenceFrequency
        self.plannedStartDate = plannedStartDate
        self.plannedEndDate = plannedEndDate
        self.listId = listId
    }
    
    /// Computed property for backward compatibility
    var priorityLevel: Int {
        priority.priorityLevel
    }
    
    /// Indicates if the reminder is high priority
    var isPriority: Bool {
        priority == .high
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