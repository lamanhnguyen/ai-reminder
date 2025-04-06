import Foundation

enum RecurrenceFrequency: String, CaseIterable, Codable {
    case daily
    case weekly
    case monthly
    case yearly
}

struct Reminder: Identifiable, Codable {
    let id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var isCompleted: Bool
    var isRecurring: Bool
    var recurrenceFrequency: RecurrenceFrequency
    var isPriority: Bool
    var listId: UUID
    
    init(id: UUID = UUID(), title: String, notes: String = "", dueDate: Date, isCompleted: Bool = false, isRecurring: Bool = false, recurrenceFrequency: RecurrenceFrequency = .daily, isPriority: Bool = false, listId: UUID) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.isRecurring = isRecurring
        self.recurrenceFrequency = recurrenceFrequency
        self.isPriority = isPriority
        self.listId = listId
    }
} 