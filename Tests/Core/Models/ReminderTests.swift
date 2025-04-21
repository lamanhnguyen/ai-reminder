import XCTest
@testable import VoiceReminders

final class ReminderTests: XCTestCase {
    func testReminderInitialization() {
        let now = Date()
        let reminder = Reminder(
            title: "Test Reminder",
            notes: "Test Notes",
            dueDate: now,
            priority: .high,
            isCompleted: true
        )
        
        XCTAssertNotNil(reminder.id)
        XCTAssertEqual(reminder.title, "Test Reminder")
        XCTAssertEqual(reminder.notes, "Test Notes")
        XCTAssertEqual(reminder.dueDate, now)
        XCTAssertEqual(reminder.priority, .high)
        XCTAssertTrue(reminder.isCompleted)
    }
    
    func testReminderDefaultValues() {
        let now = Date()
        let reminder = Reminder(title: "Test Reminder", dueDate: now)
        
        XCTAssertNotNil(reminder.id)
        XCTAssertEqual(reminder.title, "Test Reminder")
        XCTAssertNil(reminder.notes)
        XCTAssertEqual(reminder.dueDate, now)
        XCTAssertEqual(reminder.priority, .medium)
        XCTAssertFalse(reminder.isCompleted)
    }
    
    func testReminderEquality() {
        let id = UUID()
        let reminder1 = Reminder(id: id, title: "Test", dueDate: Date())
        let reminder2 = Reminder(id: id, title: "Different", dueDate: Date())
        let reminder3 = Reminder(title: "Test", dueDate: Date())
        
        XCTAssertEqual(reminder1, reminder2) // Same ID
        XCTAssertNotEqual(reminder1, reminder3) // Different ID
    }
    
    func testReminderHashing() {
        let id = UUID()
        let reminder1 = Reminder(id: id, title: "Test", dueDate: Date())
        let reminder2 = Reminder(id: id, title: "Different", dueDate: Date())
        
        var hasher1 = Hasher()
        var hasher2 = Hasher()
        reminder1.hash(into: &hasher1)
        reminder2.hash(into: &hasher2)
        
        XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
    }
    
    func testReminderPriorityRawValues() {
        XCTAssertEqual(ReminderPriority.low.rawValue, 0)
        XCTAssertEqual(ReminderPriority.medium.rawValue, 1)
        XCTAssertEqual(ReminderPriority.high.rawValue, 2)
    }
} 