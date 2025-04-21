import XCTest
import UserNotifications
@testable import VoiceReminders

final class MockNotificationCenter: UNUserNotificationCenter {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var requestAuthorizationCalled = false
    var requestAuthorizationResult: Result<Bool, Error> = .success(true)
    var addRequestCalled = false
    var addRequestError: Error?
    var removePendingRequestsCalled = false
    var removeAllPendingRequestsCalled = false
    var lastNotificationRequest: UNNotificationRequest?
    
    override func notificationSettings() async -> UNNotificationSettings {
        return MockNotificationSettings(authorizationStatus: authorizationStatus)
    }
    
    override func requestAuthorization(
        options: UNAuthorizationOptions = []
    ) async throws -> Bool {
        requestAuthorizationCalled = true
        return try requestAuthorizationResult.get()
    }
    
    override func add(_ request: UNNotificationRequest) async throws {
        addRequestCalled = true
        lastNotificationRequest = request
        if let error = addRequestError {
            throw error
        }
    }
    
    override func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removePendingRequestsCalled = true
    }
    
    override func removeAllPendingNotificationRequests() {
        removeAllPendingRequestsCalled = true
    }
}

final class MockNotificationSettings: UNNotificationSettings {
    private let _authorizationStatus: UNAuthorizationStatus
    
    init(authorizationStatus: UNAuthorizationStatus) {
        self._authorizationStatus = authorizationStatus
        super.init()
    }
    
    override var authorizationStatus: UNAuthorizationStatus {
        return _authorizationStatus
    }
}

final class NotificationServiceTests: XCTestCase {
    var mockNotificationCenter: MockNotificationCenter!
    var notificationService: NotificationService!
    var testReminder: Reminder!
    
    override func setUp() {
        super.setUp()
        mockNotificationCenter = MockNotificationCenter()
        notificationService = NotificationService(notificationCenter: mockNotificationCenter)
        testReminder = Reminder(
            id: UUID(),
            title: "Test Reminder",
            notes: "Test Notes",
            dueDate: Date(),
            priority: .medium
        )
    }
    
    override func tearDown() {
        mockNotificationCenter = nil
        notificationService = nil
        testReminder = nil
        super.tearDown()
    }
    
    // MARK: - Permission Tests
    
    func testRequestPermissionsWhenNotDetermined() async throws {
        mockNotificationCenter.authorizationStatus = .notDetermined
        mockNotificationCenter.requestAuthorizationResult = .success(true)
        
        let result = try await notificationService.requestNotificationPermissions()
        
        XCTAssertTrue(result)
        XCTAssertTrue(mockNotificationCenter.requestAuthorizationCalled)
    }
    
    func testRequestPermissionsWhenAlreadyAuthorized() async throws {
        mockNotificationCenter.authorizationStatus = .authorized
        
        let result = try await notificationService.requestNotificationPermissions()
        
        XCTAssertTrue(result)
        XCTAssertFalse(mockNotificationCenter.requestAuthorizationCalled)
    }
    
    func testRequestPermissionsWhenDenied() async throws {
        mockNotificationCenter.authorizationStatus = .denied
        
        let result = try await notificationService.requestNotificationPermissions()
        
        XCTAssertFalse(result)
        XCTAssertFalse(mockNotificationCenter.requestAuthorizationCalled)
    }
    
    // MARK: - Scheduling Tests
    
    func testScheduleNotificationSuccess() async throws {
        mockNotificationCenter.authorizationStatus = .authorized
        
        try await notificationService.scheduleReminderNotification(for: testReminder)
        
        XCTAssertTrue(mockNotificationCenter.addRequestCalled)
        XCTAssertNotNil(mockNotificationCenter.lastNotificationRequest)
        XCTAssertEqual(mockNotificationCenter.lastNotificationRequest?.identifier, testReminder.id.uuidString)
        
        let content = mockNotificationCenter.lastNotificationRequest?.content
        XCTAssertEqual(content?.title, "⚡️ \(testReminder.title)")
        XCTAssertEqual(content?.body, testReminder.notes)
        XCTAssertNotNil(mockNotificationCenter.lastNotificationRequest?.trigger)
    }
    
    func testScheduleNotificationWhenUnauthorized() async {
        mockNotificationCenter.authorizationStatus = .denied
        
        do {
            try await notificationService.scheduleReminderNotification(for: testReminder)
            XCTFail("Expected error to be thrown")
        } catch ServiceError.notificationPermissionDenied {
            XCTAssertFalse(mockNotificationCenter.addRequestCalled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testScheduleNotificationWithSchedulingError() async {
        mockNotificationCenter.authorizationStatus = .authorized
        mockNotificationCenter.addRequestError = NSError(domain: "test", code: 1)
        
        do {
            try await notificationService.scheduleReminderNotification(for: testReminder)
            XCTFail("Expected error to be thrown")
        } catch ServiceError.notificationSchedulingFailed {
            XCTAssertTrue(mockNotificationCenter.addRequestCalled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Cancellation Tests
    
    func testCancelReminderNotification() async {
        await notificationService.cancelReminderNotification(for: testReminder)
        
        XCTAssertTrue(mockNotificationCenter.removePendingRequestsCalled)
    }
    
    func testCancelAllNotifications() async {
        await notificationService.cancelAllNotifications()
        
        XCTAssertTrue(mockNotificationCenter.removeAllPendingRequestsCalled)
    }
    
    // MARK: - Priority Tests
    
    func testNotificationTitleWithHighPriority() async throws {
        mockNotificationCenter.authorizationStatus = .authorized
        testReminder = Reminder(
            id: UUID(),
            title: "High Priority",
            notes: nil,
            dueDate: Date(),
            priority: .high
        )
        
        try await notificationService.scheduleReminderNotification(for: testReminder)
        
        XCTAssertEqual(
            mockNotificationCenter.lastNotificationRequest?.content.title,
            "❗️ High Priority"
        )
    }
    
    func testNotificationTitleWithLowPriority() async throws {
        mockNotificationCenter.authorizationStatus = .authorized
        testReminder = Reminder(
            id: UUID(),
            title: "Low Priority",
            notes: nil,
            dueDate: Date(),
            priority: .low
        )
        
        try await notificationService.scheduleReminderNotification(for: testReminder)
        
        XCTAssertEqual(
            mockNotificationCenter.lastNotificationRequest?.content.title,
            "📝 Low Priority"
        )
    }
} 