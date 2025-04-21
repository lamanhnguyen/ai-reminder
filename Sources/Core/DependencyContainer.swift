import Foundation
import CoreData
import Combine

/// A container that manages all service dependencies for the app
@MainActor
final class DependencyContainer: ObservableObject {
    // MARK: - Shared Instance
    static let shared = DependencyContainer()
    
    // MARK: - Services
    private(set) lazy var remindersService: RemindersServiceProtocol = {
        RemindersService(
            coreDataService: coreDataService,
            notificationService: notificationService
        )
    }()
    
    private(set) lazy var coreDataService: CoreDataServiceProtocol = {
        CoreDataService(
            modelName: "VoiceReminders",
            inMemory: isRunningTests
        )
    }()
    
    private(set) lazy var voiceRecognitionService: VoiceRecognitionServiceProtocol = {
        VoiceRecognitionService()
    }()
    
    private(set) lazy var notificationService: NotificationServiceProtocol = {
        NotificationService()
    }()
    
    // MARK: - State Management
    
    @Published private(set) var isInitialized = false
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe any service state changes that might affect the app
        notificationService.authorizationStatus
            .sink { [weak self] status in
                // Handle notification authorization changes
                self?.handleNotificationAuthorizationChange(status)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func initialize() async {
        // Perform any necessary async initialization
        await notificationService.requestAuthorization()
        isInitialized = true
    }
    
    func reset() {
        // Reset all services to their initial state
        cancellables.removeAll()
        if let resetableService = remindersService as? Resettable {
            resetableService.reset()
        }
        if let resetableService = coreDataService as? Resettable {
            resetableService.reset()
        }
        if let resetableService = voiceRecognitionService as? Resettable {
            resetableService.reset()
        }
        if let resetableService = notificationService as? Resettable {
            resetableService.reset()
        }
        
        // Clear stored service instances
        _remindersService = nil
        _coreDataService = nil
        _voiceRecognitionService = nil
        _notificationService = nil
    }
    
    // MARK: - Private Methods
    
    private func handleNotificationAuthorizationChange(_ status: NotificationAuthorizationStatus) {
        // Handle changes in notification authorization
        // This could trigger UI updates or affect reminder functionality
    }
    
    // MARK: - Testing Support
    
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
    
    static func createForTesting(
        remindersService: RemindersServiceProtocol? = nil,
        coreDataService: CoreDataServiceProtocol? = nil,
        voiceRecognitionService: VoiceRecognitionServiceProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil
    ) -> DependencyContainer {
        let container = DependencyContainer()
        
        // Override services with provided mock implementations
        if let remindersService = remindersService {
            container._remindersService = remindersService
        }
        if let coreDataService = coreDataService {
            container._coreDataService = coreDataService
        }
        if let voiceRecognitionService = voiceRecognitionService {
            container._voiceRecognitionService = voiceRecognitionService
        }
        if let notificationService = notificationService {
            container._notificationService = notificationService
        }
        
        return container
    }
    
    // Private properties for testing overrides
    private var _remindersService: RemindersServiceProtocol?
    private var _coreDataService: CoreDataServiceProtocol?
    private var _voiceRecognitionService: VoiceRecognitionServiceProtocol?
    private var _notificationService: NotificationServiceProtocol?
}

// MARK: - Resettable Protocol

protocol Resettable {
    func reset()
}

// MARK: - Service Extensions

extension RemindersService: Resettable {
    func reset() {
        // Clear any cached data or state
    }
}

extension CoreDataService: Resettable {
    func reset() {
        // Delete all stored data and recreate store
    }
}

extension VoiceRecognitionService: Resettable {
    func reset() {
        // Reset recognition state
    }
}

extension NotificationService: Resettable {
    func reset() {
        // Clear all scheduled notifications
    }
} 