import Foundation

/// Protocol defining the requirements for service registration
protocol ServiceRegistration {
    /// The type of service being registered
    associatedtype ServiceType
    
    /// Register a service implementation
    /// - Parameters:
    ///   - implementation: The concrete implementation of the service
    ///   - asPrimaryImplementation: Whether this should be the primary implementation for the service type
    func register(_ implementation: ServiceType, asPrimaryImplementation: Bool)
    
    /// Get the registered service implementation
    /// - Returns: The registered service implementation
    func resolve() -> ServiceType?
}

/// Protocol defining the requirements for a dependency container
protocol DependencyContainerProtocol {
    /// Register a service with the container
    /// - Parameters:
    ///   - type: The type of service to register
    ///   - implementation: The concrete implementation of the service
    ///   - asPrimaryImplementation: Whether this should be the primary implementation for the service type
    func register<T>(_ type: T.Type, implementation: Any, asPrimaryImplementation: Bool)
    
    /// Resolve a service from the container
    /// - Parameter type: The type of service to resolve
    /// - Returns: The resolved service implementation
    func resolve<T>(_ type: T.Type) -> T?
}

/// A container for managing app-wide dependencies
final class DependencyContainer: DependencyContainerProtocol {
    /// Shared instance of the dependency container
    static let shared = DependencyContainer()
    
    // MARK: - Services
    private(set) lazy var coreDataService: CoreDataServiceProtocol = CoreDataService()
    private(set) lazy var remindersService: RemindersServiceProtocol = RemindersService(coreDataService: coreDataService)
    private(set) lazy var voiceRecognitionService: VoiceRecognitionServiceProtocol = VoiceRecognitionService()
    private(set) lazy var notificationService: NotificationServiceProtocol = NotificationService()
    private(set) lazy var settingsService: SettingsServiceProtocol = SettingsService()
    
    // MARK: - Environment Objects
    private(set) lazy var errorHandler = ErrorMiddleware()
    
    // MARK: - Initialization
    private init() {}
    
    /// Reset all services (useful for testing)
    func reset() {
        // Reset services to their initial state
        if let resetService = settingsService as? Resettable {
            resetService.reset()
        }
        
        // Cancel all notifications
        Task {
            try? await notificationService.cancelAllNotifications()
        }
    }
    
    // MARK: - Service Registration
    
    func register<T>(_ type: T.Type, implementation: Any, asPrimaryImplementation: Bool = false) {
        let key = String(describing: type)
        services[key] = implementation
        
        if asPrimaryImplementation {
            primaryServices[key] = implementation
        }
    }
    
    // MARK: - Service Resolution
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        // First try to get the primary implementation
        if let primaryService = primaryServices[key] as? T {
            return primaryService
        }
        
        // Fall back to any registered implementation
        return services[key] as? T
    }
    
    // MARK: - Container Management
    
    /// Dictionary storing service implementations
    private var services: [String: Any] = [:]
    
    /// Dictionary storing primary service implementations
    private var primaryServices: [String: Any] = [:]
}

/// Extension to provide type-safe service registration
extension DependencyContainer {
    /// Register a service with type inference
    /// - Parameters:
    ///   - implementation: The concrete implementation of the service
    ///   - asPrimaryImplementation: Whether this should be the primary implementation
    func register<T>(_ implementation: T, asPrimaryImplementation: Bool = false) {
        register(T.self, implementation: implementation, asPrimaryImplementation: asPrimaryImplementation)
    }
}

/// Protocol for services that can be reset to their initial state
protocol Resettable {
    /// Reset the service to its initial state
    func reset()
}

/// Environment key for accessing the dependency container
struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

/// Environment values extension for easy access to the dependency container
extension EnvironmentValues {
    var container: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
} 