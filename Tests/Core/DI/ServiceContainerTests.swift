import XCTest
@testable import VoiceReminders

final class ServiceContainerTests: XCTestCase {
    
    // MARK: - Mock Services
    
    private class MockCoreDataService: CoreDataServiceProtocol {}
    private class MockRemindersService: RemindersServiceProtocol {}
    private class MockVoiceRecognitionService: VoiceRecognitionServiceProtocol {}
    private class MockNotificationService: NotificationServiceProtocol {}
    
    // MARK: - Properties
    
    private var container: ServiceContainer!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        container = ServiceContainer.shared
        container.reset() // Ensure we start with a clean state
    }
    
    override func tearDown() {
        container.reset()
        container = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testInitialState() {
        // Initially all services should be nil
        XCTAssertNil(container.coreDataService)
        XCTAssertNil(container.remindersService)
        XCTAssertNil(container.voiceRecognitionService)
        XCTAssertNil(container.notificationService)
    }
    
    func testRegisterCoreDataService() {
        // Given
        let mockService = MockCoreDataService()
        
        // When
        container.register(coreDataService: mockService)
        
        // Then
        XCTAssertNotNil(container.coreDataService)
        XCTAssert(container.coreDataService is MockCoreDataService)
    }
    
    func testRegisterRemindersService() {
        // Given
        let mockService = MockRemindersService()
        
        // When
        container.register(remindersService: mockService)
        
        // Then
        XCTAssertNotNil(container.remindersService)
        XCTAssert(container.remindersService is MockRemindersService)
    }
    
    func testRegisterVoiceRecognitionService() {
        // Given
        let mockService = MockVoiceRecognitionService()
        
        // When
        container.register(voiceRecognitionService: mockService)
        
        // Then
        XCTAssertNotNil(container.voiceRecognitionService)
        XCTAssert(container.voiceRecognitionService is MockVoiceRecognitionService)
    }
    
    func testRegisterNotificationService() {
        // Given
        let mockService = MockNotificationService()
        
        // When
        container.register(notificationService: mockService)
        
        // Then
        XCTAssertNotNil(container.notificationService)
        XCTAssert(container.notificationService is MockNotificationService)
    }
    
    func testReset() {
        // Given
        container.register(coreDataService: MockCoreDataService())
        container.register(remindersService: MockRemindersService())
        container.register(voiceRecognitionService: MockVoiceRecognitionService())
        container.register(notificationService: MockNotificationService())
        
        // When
        container.reset()
        
        // Then
        XCTAssertNil(container.coreDataService)
        XCTAssertNil(container.remindersService)
        XCTAssertNil(container.voiceRecognitionService)
        XCTAssertNil(container.notificationService)
    }
    
    func testSharedInstance() {
        // Given
        let firstReference = ServiceContainer.shared
        let secondReference = ServiceContainer.shared
        
        // Then
        XCTAssert(firstReference === secondReference, "Shared instance should return the same instance")
    }
} 