import XCTest
@testable import VoiceReminders

@MainActor
final class ReminderFormViewModelTests: XCTestCase {
    private var mockRemindersService: MockRemindersService!
    private var viewModel: ReminderFormViewModel!
    
    override func setUp() async throws {
        mockRemindersService = MockRemindersService()
        viewModel = ReminderFormViewModel(remindersService: mockRemindersService)
    }
    
    override func tearDown() async throws {
        mockRemindersService = nil
        viewModel = nil
    }
    
    // MARK: - Initialization Tests
    func testInitWithoutReminder() {
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertNil(viewModel.dueDate)
        XCTAssertEqual(viewModel.priority, .medium)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertNil(viewModel.titleError)
    }
    
    func testInitWithReminder() {
        let reminder = Reminder(
            id: UUID(),
            title: "Test Reminder",
            notes: "Test Notes",
            dueDate: Date(),
            priority: .high,
            isCompleted: false
        )
        
        let viewModel = ReminderFormViewModel(remindersService: mockRemindersService, reminder: reminder)
        
        XCTAssertEqual(viewModel.title, reminder.title)
        XCTAssertEqual(viewModel.notes, reminder.notes ?? "")
        XCTAssertEqual(viewModel.dueDate, reminder.dueDate)
        XCTAssertEqual(viewModel.priority, reminder.priority)
    }
    
    // MARK: - Validation Tests
    func testValidationWithEmptyTitle() {
        viewModel.title = ""
        XCTAssertFalse(viewModel.isValid)
        XCTAssertEqual(viewModel.titleError, "Title is required")
    }
    
    func testValidationWithWhitespaceTitle() {
        viewModel.title = "   "
        XCTAssertFalse(viewModel.isValid)
        XCTAssertEqual(viewModel.titleError, "Title is required")
    }
    
    func testValidationWithLongTitle() {
        viewModel.title = String(repeating: "a", count: 101)
        XCTAssertFalse(viewModel.isValid)
        XCTAssertEqual(viewModel.titleError, "Title must be less than 100 characters")
    }
    
    func testValidationWithValidTitle() {
        viewModel.title = "Valid Title"
        XCTAssertTrue(viewModel.isValid)
        XCTAssertNil(viewModel.titleError)
    }
    
    // MARK: - Save Tests
    func testSaveNewReminder() async throws {
        viewModel.title = "New Reminder"
        viewModel.notes = "Some notes"
        viewModel.priority = .high
        viewModel.dueDate = Date()
        
        try await viewModel.save()
        
        XCTAssertEqual(mockRemindersService.createReminderCallCount, 1)
        XCTAssertEqual(mockRemindersService.updateReminderCallCount, 0)
        
        let createdReminder = try XCTUnwrap(mockRemindersService.lastCreatedReminder)
        XCTAssertEqual(createdReminder.title, "New Reminder")
        XCTAssertEqual(createdReminder.notes, "Some notes")
        XCTAssertEqual(createdReminder.priority, .high)
        XCTAssertEqual(createdReminder.dueDate, viewModel.dueDate)
        XCTAssertFalse(createdReminder.isCompleted)
    }
    
    func testSaveExistingReminder() async throws {
        let existingReminder = Reminder(
            id: UUID(),
            title: "Original Title",
            notes: "Original Notes",
            dueDate: Date(),
            priority: .low,
            isCompleted: true
        )
        
        viewModel = ReminderFormViewModel(remindersService: mockRemindersService, reminder: existingReminder)
        viewModel.title = "Updated Title"
        viewModel.notes = "Updated Notes"
        viewModel.priority = .high
        
        try await viewModel.save()
        
        XCTAssertEqual(mockRemindersService.createReminderCallCount, 0)
        XCTAssertEqual(mockRemindersService.updateReminderCallCount, 1)
        
        let updatedReminder = try XCTUnwrap(mockRemindersService.lastUpdatedReminder)
        XCTAssertEqual(updatedReminder.id, existingReminder.id)
        XCTAssertEqual(updatedReminder.title, "Updated Title")
        XCTAssertEqual(updatedReminder.notes, "Updated Notes")
        XCTAssertEqual(updatedReminder.priority, .high)
        XCTAssertTrue(updatedReminder.isCompleted)
    }
    
    func testSaveWithInvalidTitle() async {
        viewModel.title = ""
        
        do {
            try await viewModel.save()
            XCTFail("Save should throw an error when form is invalid")
        } catch ReminderFormViewModel.ValidationError.invalidForm {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        XCTAssertEqual(mockRemindersService.createReminderCallCount, 0)
        XCTAssertEqual(mockRemindersService.updateReminderCallCount, 0)
    }
    
    func testSaveWithServiceError() async {
        viewModel.title = "Test Title"
        mockRemindersService.shouldThrowError = true
        
        do {
            try await viewModel.save()
            XCTFail("Save should throw an error when service fails")
        } catch {
            XCTAssertNotNil(viewModel.error)
            XCTAssertEqual(error as? MockRemindersService.MockError, .someError)
        }
    }
    
    // MARK: - Clear Form Tests
    func testClearForm() {
        viewModel.title = "Test"
        viewModel.notes = "Notes"
        viewModel.dueDate = Date()
        viewModel.priority = .high
        viewModel.error = MockRemindersService.MockError.someError
        
        viewModel.clearForm()
        
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertNil(viewModel.dueDate)
        XCTAssertEqual(viewModel.priority, .medium)
        XCTAssertNil(viewModel.error)
        XCTAssertNil(viewModel.titleError)
    }
}

// MARK: - Mock Reminders Service
private final class MockRemindersService: RemindersServiceProtocol {
    enum MockError: Error {
        case someError
    }
    
    var createReminderCallCount = 0
    var updateReminderCallCount = 0
    var lastCreatedReminder: Reminder?
    var lastUpdatedReminder: Reminder?
    var shouldThrowError = false
    
    func createReminder(_ reminder: Reminder) async throws {
        if shouldThrowError {
            throw MockError.someError
        }
        createReminderCallCount += 1
        lastCreatedReminder = reminder
    }
    
    func updateReminder(_ reminder: Reminder) async throws {
        if shouldThrowError {
            throw MockError.someError
        }
        updateReminderCallCount += 1
        lastUpdatedReminder = reminder
    }
    
    func deleteReminder(_ reminder: Reminder) async throws {
        fatalError("Not implemented")
    }
    
    func toggleReminderCompletion(_ reminder: Reminder) async throws {
        fatalError("Not implemented")
    }
    
    func loadReminders() async throws -> [Reminder] {
        fatalError("Not implemented")
    }
    
    var remindersPublisher: AnyPublisher<[Reminder], Never> {
        Empty().eraseToAnyPublisher()
    }
} 