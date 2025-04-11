import Foundation

enum RecurrenceFrequency: String, CaseIterable, Codable {
    case daily
    case weekly
    case biweekly
    case monthly
    case yearly
}

struct Reminder: Identifiable, Codable {
    let id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var endDate: Date
    var isCompleted: Bool
    var isRecurring: Bool
    var recurrenceFrequency: RecurrenceFrequency
    var priorityLevel: Int // 1-5, 1 being most important
    var plannedStartDate: Date?
    var plannedEndDate: Date?
    var listId: UUID
    
    init(id: UUID = UUID(), 
         title: String, 
         notes: String = "", 
         dueDate: Date, 
         endDate: Date? = nil, 
         isCompleted: Bool = false, 
         isRecurring: Bool = false, 
         recurrenceFrequency: RecurrenceFrequency = .daily, 
         priorityLevel: Int = 3,
         plannedStartDate: Date? = nil,
         plannedEndDate: Date? = nil,
         listId: UUID) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.endDate = endDate ?? dueDate.addingTimeInterval(3600)
        self.isCompleted = isCompleted
        self.isRecurring = isRecurring
        self.recurrenceFrequency = recurrenceFrequency
        self.priorityLevel = min(max(priorityLevel, 1), 5) // Ensure priority is between 1-5
        self.plannedStartDate = plannedStartDate
        self.plannedEndDate = plannedEndDate
        self.listId = listId
    }
    
    var isPriority: Bool {
        priorityLevel <= 2 // Consider priority 1-2 as high priority for backward compatibility
    }
} 