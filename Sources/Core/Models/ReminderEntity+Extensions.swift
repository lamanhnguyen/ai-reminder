import CoreData
import Foundation

extension ReminderEntity {
    func toDomain() -> Reminder {
        Reminder(
            id: id ?? UUID().uuidString,
            title: title ?? "",
            notes: notes,
            dueDate: dueDate,
            priority: ReminderPriority(rawValue: Int(priority)) ?? .medium,
            isCompleted: isCompleted,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
    
    static func fromDomain(_ reminder: Reminder, context: NSManagedObjectContext) -> ReminderEntity {
        let entity = ReminderEntity(context: context)
        entity.update(from: reminder)
        return entity
    }
    
    func update(from reminder: Reminder) {
        self.id = reminder.id
        self.title = reminder.title
        self.notes = reminder.notes
        self.dueDate = reminder.dueDate
        self.priority = Int16(reminder.priority.rawValue)
        self.isCompleted = reminder.isCompleted
        self.createdAt = reminder.createdAt
        self.updatedAt = reminder.updatedAt
    }
} 