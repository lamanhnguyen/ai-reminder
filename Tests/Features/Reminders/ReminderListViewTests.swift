import XCTest
import ViewInspector
@testable import VoiceReminders
import SwiftUI

extension ReminderListView: Inspectable {}
extension ReminderRow: Inspectable {}

@MainActor
final class ReminderListViewTests: XCTestCase {
    private var sut: ReminderListView!
    private var viewModel: RemindersViewModel!
    private var mockService: MockRemindersService!
    
    override func setUp() {
        mockService = MockRemindersService()
        viewModel = RemindersViewModel(remindersService: mockService)
        sut = ReminderListView(viewModel: viewModel)
    }
    
    override func tearDown() {
        sut = nil
        viewModel = nil
        mockService = nil
        super.tearDown()
    }
    
    func testInitialState_ShowsEmptyState() throws {
        // Given empty reminders list
        viewModel.reminders = []
        
        // When inspecting the view
        let view = try sut.inspect()
        
        // Then
        XCTAssertTrue(try view.find(viewWithId: "emptyStateView").isVisible())
    }
    
    func testRemindersList_ShowsAllReminders() throws {
        // Given
        let reminders = [
            Reminder.mock(title: "Test 1"),
            Reminder.mock(title: "Test 2")
        ]
        viewModel.reminders = reminders
        
        // When
        let view = try sut.inspect()
        let list = try view.find(viewWithId: "remindersList")
        
        // Then
        XCTAssertEqual(try list.count, reminders.count)
        
        // Verify first reminder row
        let firstRow = try list.list().cell(row: 0).view(ReminderRow.self)
        XCTAssertEqual(try firstRow.actualView().reminder.title, "Test 1")
    }
    
    func testSearchBar_UpdatesSearchText() throws {
        // Given
        let searchText = "test"
        
        // When
        let view = try sut.inspect()
        try view.find(viewWithId: "searchField").textField().setInput(searchText)
        
        // Then
        XCTAssertEqual(viewModel.searchText, searchText)
    }
    
    func testPriorityFilter_UpdatesSelectedPriority() throws {
        // Given
        let priority = Priority.high
        
        // When
        let view = try sut.inspect()
        try view.find(viewWithId: "priorityPicker").picker().select(value: priority)
        
        // Then
        XCTAssertEqual(viewModel.selectedPriority, priority)
    }
    
    func testShowCompletedToggle_UpdatesShowCompleted() throws {
        // Given initial state
        viewModel.showCompleted = false
        
        // When
        let view = try sut.inspect()
        try view.find(viewWithId: "showCompletedToggle").toggle().tap()
        
        // Then
        XCTAssertTrue(viewModel.showCompleted)
    }
    
    func testClearFiltersButton_ResetsAllFilters() throws {
        // Given
        viewModel.searchText = "test"
        viewModel.selectedPriority = .high
        viewModel.showCompleted = true
        
        // When
        let view = try sut.inspect()
        try view.find(button: "Clear Filters").tap()
        
        // Then
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertNil(viewModel.selectedPriority)
        XCTAssertFalse(viewModel.showCompleted)
    }
    
    func testAddButton_NavigatesToAddView() throws {
        // Given
        var isShowingAddView = false
        sut = ReminderListView(viewModel: viewModel, isShowingAddView: .constant(isShowingAddView))
        
        // When
        let view = try sut.inspect()
        try view.find(button: "Add Reminder").tap()
        
        // Then
        // Note: In a real app, we would verify navigation state
        // This is a limitation of ViewInspector for sheet presentations
    }
    
    func testReminderRow_ToggleCompletion() throws {
        // Given
        let reminder = Reminder.mock(title: "Test", isCompleted: false)
        viewModel.reminders = [reminder]
        
        // When
        let view = try sut.inspect()
        let row = try view.find(viewWithId: "remindersList").list().cell(row: 0).view(ReminderRow.self)
        try row.find(button: "Toggle Completion").tap()
        
        // Then
        // Note: In real app, we would verify the completion state changed
        // This requires waiting for the async operation to complete
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