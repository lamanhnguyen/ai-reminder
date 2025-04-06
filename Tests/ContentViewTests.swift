import XCTest
@testable import VoiceReminders

class ContentViewTests: XCTestCase {
    var reminderManager: ReminderManager!
    var voiceRecognizer: VoiceRecognizer!
    
    override func setUp() {
        super.setUp()
        reminderManager = ReminderManager()
        voiceRecognizer = VoiceRecognizer(audioEngine: AVAudioEngine())
    }
    
    override func tearDown() {
        reminderManager = nil
        voiceRecognizer = nil
        super.tearDown()
    }
    
    func testReminderManagerInitialLists() {
        // Check that default lists are created
        XCTAssertFalse(reminderManager.lists.isEmpty, "ReminderManager should create default lists")
        XCTAssertEqual(reminderManager.lists.count, 3, "ReminderManager should create 3 default lists")
        
        // Check list names
        let listNames = reminderManager.lists.map { $0.name }
        XCTAssertTrue(listNames.contains("Personal"), "Default lists should include 'Personal'")
        XCTAssertTrue(listNames.contains("Work"), "Default lists should include 'Work'")
        XCTAssertTrue(listNames.contains("Shopping"), "Default lists should include 'Shopping'")
    }
    
    func testAddingReminder() {
        guard let firstListId = reminderManager.lists.first?.id else {
            XCTFail("No lists available")
            return
        }
        
        // Initial count
        let initialCount = reminderManager.lists.first?.reminders.count ?? 0
        
        // Add a reminder
        reminderManager.addReminder("Test Reminder", dueDate: Date(), to: firstListId)
        
        // Verify the reminder was added
        let newCount = reminderManager.lists.first?.reminders.count ?? 0
        XCTAssertEqual(newCount, initialCount + 1, "Reminder count should increase by 1")
        
        // Verify reminder properties
        let reminder = reminderManager.lists.first?.reminders.last
        XCTAssertEqual(reminder?.title, "Test Reminder", "Reminder should have the correct title")
    }
    
    func testToggleReminder() {
        guard let firstListId = reminderManager.lists.first?.id else {
            XCTFail("No lists available")
            return
        }
        
        // Add a reminder
        reminderManager.addReminder("Test Reminder", dueDate: Date(), to: firstListId)
        
        // Get the reminder
        guard let reminder = reminderManager.lists.first?.reminders.last else {
            XCTFail("Reminder not added")
            return
        }
        
        // Initial state should be not completed
        XCTAssertFalse(reminder.isCompleted, "Reminder should start as not completed")
        
        // Toggle the reminder
        reminderManager.toggleReminder(reminder, in: firstListId)
        
        // Get the updated reminder
        guard let updatedReminder = reminderManager.lists.first?.reminders.last else {
            XCTFail("Reminder not found after toggle")
            return
        }
        
        // Verify the reminder was toggled
        XCTAssertTrue(updatedReminder.isCompleted, "Reminder should be toggled to completed")
    }
} 