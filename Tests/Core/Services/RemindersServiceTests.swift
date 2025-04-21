import XCTest
import Combine
@testable import VoiceReminders

final class RemindersServiceTests: XCTestCase {
    // MARK: - Properties
    private var sut: RemindersService!
    private var mockCoreDataService: MockCoreDataService!
    private var mockNotificationService: MockNotificationService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockCoreDataService = MockCoreDataService()
        mockNotificationService = MockNotificationService()
        sut = RemindersService(coreDataService: mockCoreDataService, notificationService: mockNotificationService)
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        mockCoreDataService = nil
        mockNotificationService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Test Data
    private func createTestReminder(isCompleted: Bool = false, dueDate: Date? = Date()) -> Reminder {
        Reminder(
            id: UUID(),
            title: "Test Reminder",
            notes: "Test Notes",
            dueDate: dueDate,
            priority: .medium,
            isCompleted: isCompleted
        )
    }
    
    // MARK: - Create Tests
    func testCreateReminder_WithDueDate_SchedulesNotification() async throws {
        // Given
        let reminder = createTestReminder()
        
        // When
        try await sut.createReminder(reminder)
        
        // Then
        XCTAssertTrue(mockCoreDataService.createReminderCalled)
        XCTAssertTrue(mockNotificationService.scheduleNotificationCalled)
        XCTAssertEqual(mockCoreDataService.lastCreatedReminder?.id, reminder.id)
    }
    
    func testCreateReminder_WithoutDueDate_DoesNotScheduleNotification() async throws {
        // Given
        let reminder = createTestReminder(dueDate: nil)
        
        // When
        try await sut.createReminder(reminder)
        
        // Then
        XCTAssertTrue(mockCoreDataService.createReminderCalled)
        XCTAssertFalse(mockNotificationService.scheduleNotificationCalled)
    }
    
    // MARK: - Update Tests
    func testUpdateReminder_WithDueDate_UpdatesNotification() async throws {
        // Given
        let reminder = createTestReminder()
        
        // When
        try await sut.updateReminder(reminder)
        
        // Then
        XCTAssertTrue(mockCoreDataService.updateReminderCalled)
        XCTAssertTrue(mockNotificationService.cancelNotificationCalled)
        XCTAssertTrue(mockNotificationService.scheduleNotificationCalled)
    }
    
    func testUpdateReminder_WhenCompleted_CancelsNotification() async throws {
        // Given
        let reminder = createTestReminder(isCompleted: true)
        
        // When
        try await sut.updateReminder(reminder)
        
        // Then
        XCTAssertTrue(mockCoreDataService.updateReminderCalled)
        XCTAssertTrue(mockNotificationService.cancelNotificationCalled)
        XCTAssertFalse(mockNotificationService.scheduleNotificationCalled)
    }
    
    // MARK: - Delete Tests
    func testDeleteReminder_CancelsNotificationAndDeletesFromCoreData() async throws {
        // Given
        let reminder = createTestReminder()
        
        // When
        try await sut.deleteReminder(reminder)
        
        // Then
        XCTAssertTrue(mockCoreDataService.deleteReminderCalled)
        XCTAssertTrue(mockNotificationService.cancelNotificationCalled)
    }
    
    func testDeleteAllReminders_CancelsAllNotificationsAndDeletesAll() async throws {
        // When
        try await sut.deleteAllReminders()
        
        // Then
        XCTAssertTrue(mockCoreDataService.deleteAllRemindersCalled)
        XCTAssertTrue(mockNotificationService.cancelAllNotificationsCalled)
    }
    
    // MARK: - Toggle Completion Tests
    func testToggleReminderCompletion_WhenIncomplete_CompletesAndCancelsNotification() async throws {
        // Given
        let reminder = createTestReminder(isCompleted: false)
        
        // When
        try await sut.toggleReminderCompletion(reminder)
        
        // Then
        XCTAssertTrue(mockCoreDataService.updateReminderCalled)
        let updatedReminder = try XCTUnwrap(mockCoreDataService.lastUpdatedReminder)
        XCTAssertTrue(updatedReminder.isCompleted)
        XCTAssertTrue(mockNotificationService.cancelNotificationCalled)
        XCTAssertFalse(mockNotificationService.scheduleNotificationCalled)
    }
    
    func testToggleReminderCompletion_WhenComplete_UncompletesAndSchedulesNotification() async throws {
        // Given
        let futureDate = Date().addingTimeInterval(3600) // 1 hour in future
        let reminder = createTestReminder(isCompleted: true, dueDate: futureDate)
        
        // When
        try await sut.toggleReminderCompletion(reminder)
        
        // Then
        XCTAssertTrue(mockCoreDataService.updateReminderCalled)
        let updatedReminder = try XCTUnwrap(mockCoreDataService.lastUpdatedReminder)
        XCTAssertFalse(updatedReminder.isCompleted)
        XCTAssertTrue(mockNotificationService.scheduleNotificationCalled)
    }
    
    // MARK: - Fetch Tests
    func testFetchReminders_ReturnsRemindersFromCoreData() async throws {
        // Given
        let expectedReminders = [createTestReminder(), createTestReminder()]
        mockCoreDataService.remindersToReturn = expectedReminders
        
        // When
        let reminders = try await sut.fetchReminders()
        
        // Then
        XCTAssertTrue(mockCoreDataService.fetchRemindersCalled)
        XCTAssertEqual(reminders.count, expectedReminders.count)
    }
    
    // MARK: - Publisher Tests
    func testRemindersPublisher_EmitsUpdatesFromCoreData() {
        // Given
        let expectation = expectation(description: "Publisher emits value")
        let expectedReminders = [createTestReminder()]
        
        // When
        sut.remindersPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { reminders in
                    // Then
                    XCTAssertEqual(reminders.count, expectedReminders.count)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        mockCoreDataService.remindersSubject.send(expectedReminders)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Services
private final class MockCoreDataService: CoreDataServiceProtocol {
    var createReminderCalled = false
    var updateReminderCalled = false
    var deleteReminderCalled = false
    var deleteAllRemindersCalled = false
    var fetchRemindersCalled = false
    
    var lastCreatedReminder: Reminder?
    var lastUpdatedReminder: Reminder?
    var remindersToReturn: [Reminder] = []
    
    let remindersSubject = PassthroughSubject<[Reminder], Error>()
    var remindersPublisher: AnyPublisher<[Reminder], Error> {
        remindersSubject.eraseToAnyPublisher()
    }
    
    func createReminder(_ reminder: Reminder) async throws {
        createReminderCalled = true
        lastCreatedReminder = reminder
    }
    
    func updateReminder(_ reminder: Reminder) async throws {
        updateReminderCalled = true
        lastUpdatedReminder = reminder
    }
    
    func deleteReminder(_ reminder: Reminder) async throws {
        deleteReminderCalled = true
    }
    
    func deleteAllReminders() async throws {
        deleteAllRemindersCalled = true
    }
    
    func fetchReminders() async throws -> [Reminder] {
        fetchRemindersCalled = true
        return remindersToReturn
    }
}

private final class MockNotificationService: NotificationServiceProtocol {
    var scheduleNotificationCalled = false
    var cancelNotificationCalled = false
    var cancelAllNotificationsCalled = false
    
    func scheduleReminderNotification(for reminder: Reminder) async throws {
        scheduleNotificationCalled = true
    }
    
    func cancelReminderNotification(for reminder: Reminder) async throws {
        cancelNotificationCalled = true
    }
    
    func cancelAllNotifications() async throws {
        cancelAllNotificationsCalled = true
    }
} 