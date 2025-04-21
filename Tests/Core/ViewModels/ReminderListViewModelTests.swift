import XCTest
import Combine
@testable import VoiceReminders

final class MockRemindersService: RemindersServiceProtocol {
    var reminders: [Reminder] = []
    var error: Error?
    private let remindersSubject = CurrentValueSubject<[Reminder], Error>([])
    
    var remindersPublisher: AnyPublisher<[Reminder], Error> {
        remindersSubject.eraseToAnyPublisher()
    }
    
    func updatePublisher(with reminders: [Reminder]) {
        self.reminders = reminders
        remindersSubject.send(reminders)
    }
    
    func sendError(_ error: Error) {
        remindersSubject.send(completion: .failure(error))
    }
    
    func getAllReminders() async throws -> [Reminder] {
        if let error = error {
            throw error
        }
        return reminders
    }
    
    func getReminders(completed: Bool) async throws -> [Reminder] {
        if let error = error {
            throw error
        }
        return reminders.filter { $0.isCompleted == completed }
    }
    
    func getReminder(id: UUID) async throws -> Reminder? {
        if let error = error {
            throw error
        }
        return reminders.first { $0.id == id }
    }
    
    func createReminder(title: String, notes: String?, dueDate: Date, priority: ReminderPriority) async throws -> Reminder {
        if let error = error {
            throw error
        }
        let reminder = Reminder(id: UUID(), title: title, notes: notes, dueDate: dueDate, priority: priority)
        reminders.append(reminder)
        updatePublisher(with: reminders)
        return reminder
    }
    
    func updateReminder(_ reminder: Reminder) async throws {
        if let error = error {
            throw error
        }
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            updatePublisher(with: reminders)
        }
    }
    
    func deleteReminder(_ reminder: Reminder) async throws {
        if let error = error {
            throw error
        }
        reminders.removeAll { $0.id == reminder.id }
        updatePublisher(with: reminders)
    }
    
    func markReminderCompleted(_ reminder: Reminder, completed: Bool) async throws {
        if let error = error {
            throw error
        }
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            var updatedReminder = reminder
            updatedReminder.isCompleted = completed
            reminders[index] = updatedReminder
            updatePublisher(with: reminders)
        }
    }
}

final class ReminderListViewModelTests: XCTestCase {
    var mockService: MockRemindersService!
    var viewModel: ReminderListViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockService = MockRemindersService()
        viewModel = ReminderListViewModel(remindersService: mockService)
        cancellables = []
    }
    
    override func tearDown() {
        mockService = nil
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(viewModel.reminders.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.showCompleted)
        XCTAssertTrue(viewModel.searchText.isEmpty)
    }
    
    // MARK: - Filtering Tests
    
    func testFilterByCompletionStatus() {
        let completedReminder = Reminder(id: UUID(), title: "Completed", dueDate: Date(), isCompleted: true)
        let incompleteReminder = Reminder(id: UUID(), title: "Incomplete", dueDate: Date(), isCompleted: false)
        mockService.updatePublisher(with: [completedReminder, incompleteReminder])
        
        // Test incomplete reminders
        viewModel.showCompleted = false
        XCTAssertEqual(viewModel.filteredReminders.count, 1)
        XCTAssertEqual(viewModel.filteredReminders.first?.title, "Incomplete")
        
        // Test completed reminders
        viewModel.showCompleted = true
        XCTAssertEqual(viewModel.filteredReminders.count, 1)
        XCTAssertEqual(viewModel.filteredReminders.first?.title, "Completed")
    }
    
    func testSearchFiltering() {
        let reminders = [
            Reminder(id: UUID(), title: "Buy groceries", notes: "Milk and bread", dueDate: Date()),
            Reminder(id: UUID(), title: "Call mom", notes: nil, dueDate: Date()),
            Reminder(id: UUID(), title: "Pay bills", notes: "Electricity bill", dueDate: Date())
        ]
        mockService.updatePublisher(with: reminders)
        
        // Test title search
        viewModel.searchText = "groceries"
        XCTAssertEqual(viewModel.filteredReminders.count, 1)
        XCTAssertEqual(viewModel.filteredReminders.first?.title, "Buy groceries")
        
        // Test notes search
        viewModel.searchText = "electricity"
        XCTAssertEqual(viewModel.filteredReminders.count, 1)
        XCTAssertEqual(viewModel.filteredReminders.first?.title, "Pay bills")
        
        // Test case insensitive search
        viewModel.searchText = "GROCERIES"
        XCTAssertEqual(viewModel.filteredReminders.count, 1)
        XCTAssertEqual(viewModel.filteredReminders.first?.title, "Buy groceries")
    }
    
    // MARK: - Sorting Tests
    
    func testReminderSorting() {
        let now = Date()
        let later = now.addingTimeInterval(3600)
        let reminders = [
            Reminder(id: UUID(), title: "Low Priority Later", dueDate: later, priority: .low),
            Reminder(id: UUID(), title: "High Priority Now", dueDate: now, priority: .high),
            Reminder(id: UUID(), title: "Medium Priority Now", dueDate: now, priority: .medium)
        ]
        mockService.updatePublisher(with: reminders)
        
        let sortedReminders = viewModel.filteredReminders
        XCTAssertEqual(sortedReminders.count, 3)
        XCTAssertEqual(sortedReminders[0].title, "High Priority Now")
        XCTAssertEqual(sortedReminders[1].title, "Medium Priority Now")
        XCTAssertEqual(sortedReminders[2].title, "Low Priority Later")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async {
        let testError = ServiceError.notFound
        mockService.error = testError
        
        await viewModel.refreshReminders()
        XCTAssertNotNil(viewModel.error)
        
        if case ServiceError.notFound = viewModel.error as? ServiceError {
            // Error was properly propagated
        } else {
            XCTFail("Expected ServiceError.notFound")
        }
        
        viewModel.clearError()
        XCTAssertNil(viewModel.error)
    }
    
    // MARK: - Action Tests
    
    func testToggleCompletion() async {
        let reminder = Reminder(id: UUID(), title: "Test", dueDate: Date(), isCompleted: false)
        mockService.updatePublisher(with: [reminder])
        
        await viewModel.toggleCompletion(for: reminder)
        
        XCTAssertTrue(mockService.reminders.first?.isCompleted ?? false)
    }
    
    func testDeleteReminder() async {
        let reminder = Reminder(id: UUID(), title: "Test", dueDate: Date())
        mockService.updatePublisher(with: [reminder])
        
        await viewModel.deleteReminder(reminder)
        
        XCTAssertTrue(mockService.reminders.isEmpty)
    }
    
    func testRefreshReminders() async {
        let reminders = [
            Reminder(id: UUID(), title: "Test 1", dueDate: Date()),
            Reminder(id: UUID(), title: "Test 2", dueDate: Date())
        ]
        mockService.reminders = reminders
        
        await viewModel.refreshReminders()
        
        XCTAssertEqual(viewModel.reminders.count, 2)
        XCTAssertFalse(viewModel.isLoading)
    }
} 