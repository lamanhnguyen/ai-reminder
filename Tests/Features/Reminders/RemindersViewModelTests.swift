import XCTest
@testable import VoiceReminders
import Combine

@MainActor
final class RemindersViewModelTests: XCTestCase {
    private var sut: RemindersViewModel!
    private var mockService: MockRemindersService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        mockService = MockRemindersService()
        sut = RemindersViewModel(remindersService: mockService)
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Loading Tests
    
    func testLoadReminders_WhenSuccessful_UpdatesReminders() async {
        // Given
        let expectedReminders = [
            Reminder.mock(title: "Test 1"),
            Reminder.mock(title: "Test 2")
        ]
        mockService.mockReminders = expectedReminders
        
        // When
        await sut.loadReminders()
        
        // Then
        XCTAssertEqual(sut.reminders, expectedReminders)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testLoadReminders_WhenFails_SetsError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 1)
        mockService.mockError = expectedError
        
        // When
        await sut.loadReminders()
        
        // Then
        XCTAssertEqual((sut.error as NSError?)?.domain, expectedError.domain)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - CRUD Operation Tests
    
    func testAddReminder_WhenSuccessful_UpdatesViaPublisher() async {
        // Given
        let newReminder = Reminder.mock(title: "New Reminder")
        let updatedReminders = [newReminder]
        mockService.mockReminders = updatedReminders
        
        // When
        await sut.addReminder(newReminder)
        mockService.sendRemindersUpdate(updatedReminders)
        
        // Then
        XCTAssertEqual(sut.reminders, updatedReminders)
        XCTAssertNil(sut.error)
    }
    
    func testDeleteReminder_WhenSuccessful_RemovesFromList() async {
        // Given
        let reminder = Reminder.mock(title: "To Delete")
        sut.reminders = [reminder]
        
        // When
        await sut.deleteReminder(reminder)
        
        // Then
        XCTAssertTrue(sut.reminders.isEmpty)
        XCTAssertNil(sut.error)
    }
    
    func testToggleCompletion_WhenSuccessful_UpdatesReminder() async {
        // Given
        let reminder = Reminder.mock(title: "Test", isCompleted: false)
        sut.reminders = [reminder]
        
        // When
        await sut.toggleCompletion(for: reminder)
        
        // Then
        XCTAssertTrue(sut.reminders.first?.isCompleted ?? false)
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Filtering Tests
    
    func testFilteredReminders_WithSearchText_FiltersCorrectly() {
        // Given
        let matchingReminder = Reminder.mock(title: "Match", notes: "Test")
        let nonMatchingReminder = Reminder.mock(title: "Other", notes: "Different")
        sut.reminders = [matchingReminder, nonMatchingReminder]
        
        // When
        sut.searchText = "match"
        
        // Then
        XCTAssertEqual(sut.filteredReminders.count, 1)
        XCTAssertEqual(sut.filteredReminders.first?.title, "Match")
    }
    
    func testFilteredReminders_WithPriority_FiltersCorrectly() {
        // Given
        let highPriority = Reminder.mock(title: "High", priority: .high)
        let lowPriority = Reminder.mock(title: "Low", priority: .low)
        sut.reminders = [highPriority, lowPriority]
        
        // When
        sut.selectedPriority = .high
        
        // Then
        XCTAssertEqual(sut.filteredReminders.count, 1)
        XCTAssertEqual(sut.filteredReminders.first?.priority, .high)
    }
    
    func testFilteredReminders_ShowCompleted_FiltersCorrectly() {
        // Given
        let completed = Reminder.mock(title: "Done", isCompleted: true)
        let incomplete = Reminder.mock(title: "Todo", isCompleted: false)
        sut.reminders = [completed, incomplete]
        
        // When
        sut.showCompleted = false
        
        // Then
        XCTAssertEqual(sut.filteredReminders.count, 1)
        XCTAssertEqual(sut.filteredReminders.first?.title, "Todo")
    }
    
    func testClearFilters_ResetsAllFilters() {
        // Given
        sut.searchText = "test"
        sut.showCompleted = true
        sut.selectedPriority = .high
        
        // When
        sut.clearFilters()
        
        // Then
        XCTAssertTrue(sut.searchText.isEmpty)
        XCTAssertFalse(sut.showCompleted)
        XCTAssertNil(sut.selectedPriority)
    }
}

// MARK: - Mock Service
private class MockRemindersService: RemindersServiceProtocol {
    var mockReminders: [Reminder] = []
    var mockError: Error?
    private let remindersSubject = PassthroughSubject<[Reminder], Never>()
    
    var remindersPublisher: AnyPublisher<[Reminder], Never> {
        remindersSubject.eraseToAnyPublisher()
    }
    
    func fetchReminders() async throws -> [Reminder] {
        if let error = mockError {
            throw error
        }
        return mockReminders
    }
    
    func createReminder(_ reminder: Reminder) async throws -> Reminder {
        if let error = mockError {
            throw error
        }
        return reminder
    }
    
    func updateReminder(_ reminder: Reminder) async throws {
        if let error = mockError {
            throw error
        }
    }
    
    func deleteReminder(_ reminder: Reminder) async throws {
        if let error = mockError {
            throw error
        }
    }
    
    func deleteAllReminders() async throws {
        if let error = mockError {
            throw error
        }
    }
    
    func sendRemindersUpdate(_ reminders: [Reminder]) {
        remindersSubject.send(reminders)
    }
}

// MARK: - Reminder Factory
private extension Reminder {
    static func mock(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        dueDate: Date = Date(),
        priority: Priority = .medium,
        isCompleted: Bool = false
    ) -> Reminder {
        Reminder(
            id: id,
            title: title,
            notes: notes,
            dueDate: dueDate,
            priority: priority,
            isCompleted: isCompleted
        )
    }
} 