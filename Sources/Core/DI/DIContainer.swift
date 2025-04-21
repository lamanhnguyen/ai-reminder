import Foundation

/// Protocol for registering and resolving dependencies
public protocol DIContainerProtocol {
    /// Register a factory for creating instances of a type
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    
    /// Register a shared instance (singleton) of a type
    func registerShared<T>(_ type: T.Type, instance: T)
    
    /// Resolve an instance of a type
    func resolve<T>() -> T?
}

/// Main dependency injection container for the app
public final class DIContainer: DIContainerProtocol {
    /// Singleton instance of the container
    public static let shared = DIContainer()
    
    /// Storage for factory closures
    private var factories: [String: () -> Any] = [:]
    
    /// Storage for shared instances
    private var sharedInstances: [String: Any] = [:]
    
    private init() {}
    
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    public func registerShared<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        sharedInstances[key] = instance
    }
    
    public func resolve<T>() -> T? {
        let key = String(describing: T.self)
        
        // Check for shared instance first
        if let instance = sharedInstances[key] as? T {
            return instance
        }
        
        // Otherwise create new instance using factory
        if let factory = factories[key] {
            return factory() as? T
        }
        
        return nil
    }
    
    /// Remove all registrations
    public func reset() {
        factories.removeAll()
        sharedInstances.removeAll()
    }
}

/// Property wrapper for injecting dependencies
@propertyWrapper
public struct Injected<T> {
    private let container: DIContainerProtocol
    private var value: T?
    
    public var wrappedValue: T {
        get {
            if let value = value {
                return value
            }
            guard let resolved = container.resolve() else {
                fatalError("No registration found for type \(T.self)")
            }
            value = resolved
            return resolved
        }
    }
    
    public init(container: DIContainerProtocol = DIContainer.shared) {
        self.container = container
    }
}

/// Environment key for accessing the DI container in SwiftUI views
private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainerProtocol = DIContainer.shared
}

extension EnvironmentValues {
    public var diContainer: DIContainerProtocol {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
} 