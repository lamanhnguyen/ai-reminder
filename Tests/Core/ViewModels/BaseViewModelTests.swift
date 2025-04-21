import XCTest
@testable import VoiceReminders

final class BaseViewModelTests: XCTestCase {
    // MARK: - Properties
    
    var container: ServiceContainer!
    var viewModel: TestViewModel!
    
    // Mock services
    var mockCoreDataService: MockCoreDataService!
    var mockRemindersService: MockRemindersService!
    var mockVoiceRecognitionService: MockVoiceRecognitionService!
    var mockNotificationService: MockNotificationService!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        container = ServiceContainer()
        
        // Initialize mock services
        mockCoreDataService = MockCoreDataService()
        mockRemindersService = MockRemindersService()
        mockVoiceRecognitionService = MockVoiceRecognitionService()
        mockNotificationService = MockNotificationService()
        
        // Register mock services
        container.coreDataService = mockCoreDataService
        container.remindersService = mockRemindersService
        container.voiceRecognitionService = mockVoiceRecognitionService
        container.notificationService = mockNotificationService
        
        // Initialize test view model
        viewModel = TestViewModel(container: container)
    }
    
    override func tearDown() {
        container.reset()
        container = nil
        viewModel = nil
        mockCoreDataService = nil
        mockRemindersService = nil
        mockVoiceRecognitionService = nil
        mockNotificationService = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testServiceAccess() {
        // Test that services are accessible through the view model
        XCTAssertTrue(viewModel.coreDataService === mockCoreDataService)
        XCTAssertTrue(viewModel.remindersService === mockRemindersService)
        XCTAssertTrue(viewModel.voiceRecognitionService === mockVoiceRecognitionService)
        XCTAssertTrue(viewModel.notificationService === mockNotificationService)
    }
    
    func testServiceAccessWithoutRegistration() {
        // Create a new container without registering services
        let emptyContainer = ServiceContainer()
        let newViewModel = TestViewModel(container: emptyContainer)
        
        // Test that accessing unregistered services triggers fatal errors
        XCTAssertThrowsAssertion { _ = newViewModel.coreDataService }
        XCTAssertThrowsAssertion { _ = newViewModel.remindersService }
        XCTAssertThrowsAssertion { _ = newViewModel.voiceRecognitionService }
        XCTAssertThrowsAssertion { _ = newViewModel.notificationService }
    }
    
    func testCleanup() {
        // Add a test subscription
        let publisher = PassthroughSubject<Int, Never>()
        var receivedValue: Int?
        
        let subscription = publisher
            .sink { value in
                receivedValue = value
            }
        
        viewModel.cancellables.insert(subscription)
        
        // Verify subscription is active
        publisher.send(42)
        XCTAssertEqual(receivedValue, 42)
        
        // Call cleanup
        viewModel.cleanup()
        
        // Verify subscriptions are cancelled
        XCTAssertTrue(viewModel.cancellables.isEmpty)
        
        // Verify subscription is no longer active
        publisher.send(100)
        XCTAssertEqual(receivedValue, 42) // Value should not have changed
    }
}

// MARK: - Test Helpers

/// Test implementation of BaseViewModel for testing
private final class TestViewModel: BaseViewModel {
    var setupSubscriptionsCalled = false
    
    override func setupSubscriptions() {
        super.setupSubscriptions()
        setupSubscriptionsCalled = true
    }
}

/// Helper extension to test for fatal errors
private extension XCTest {
    func XCTAssertThrowsAssertion(_ expression: @escaping () -> Void) {
        let exp = expectation(description: "Assertion should be thrown")
        
        // Set up an exception handler
        let exception = NSException.init(name: NSExceptionName(rawValue: "Fatal error"), reason: nil, userInfo: nil)
        exception.raise()
        
        // If we get here, the assertion wasn't thrown
        XCTFail("Expected assertion was not thrown")
        
        waitForExpectations(timeout: 1.0) { error in
            if error != nil {
                XCTFail("Timeout while waiting for assertion")
            }
        }
    }
} 