import Foundation

/// Defines the lifetime of a registered service
enum ServiceLifetime {
    /// A new instance is created each time the service is requested
    case transient
    
    /// The same instance is shared within a scope (e.g., a user session)
    case scoped
    
    /// A single instance is shared across the entire application
    case singleton
}

/// Represents a registered service in the container
class ServiceRegistration {
    /// The type of service being registered
    let serviceType: Any.Type
    
    /// The factory that creates instances of the service
    let factory: (ServiceContainer) -> Any
    
    /// The lifetime of the service
    let lifetime: ServiceLifetime
    
    /// Cached instance for singleton services
    private var singletonInstance: Any?
    
    init(serviceType: Any.Type, factory: @escaping (ServiceContainer) -> Any, lifetime: ServiceLifetime) {
        self.serviceType = serviceType
        self.factory = factory
        self.lifetime = lifetime
    }
    
    /// Get or create an instance of the service based on its lifetime
    func getInstance(from container: ServiceContainer) -> Any {
        switch lifetime {
        case .transient:
            return factory(container)
        case .scoped:
            // For now, treat scoped as transient
            // In a real app, you'd want to tie this to a session or request
            return factory(container)
        case .singleton:
            if let instance = singletonInstance {
                return instance
            }
            let instance = factory(container)
            singletonInstance = instance
            return instance
        }
    }
}

/// Extension to ServiceContainer for registration methods
extension ServiceContainer {
    /// Register a service with a specific implementation and lifetime
    func register<Service, Implementation>(
        _ serviceType: Service.Type,
        implementation: Implementation.Type,
        lifetime: ServiceLifetime = .transient
    ) where Implementation: Service {
        let registration = ServiceRegistration(
            serviceType: serviceType,
            factory: { _ in Implementation() },
            lifetime: lifetime
        )
        registrations[String(describing: serviceType)] = registration
    }
    
    /// Register a service with a factory function and lifetime
    func register<Service>(
        _ serviceType: Service.Type,
        factory: @escaping (ServiceContainer) -> Service,
        lifetime: ServiceLifetime = .transient
    ) {
        let registration = ServiceRegistration(
            serviceType: serviceType,
            factory: { container in factory(container) },
            lifetime: lifetime
        )
        registrations[String(describing: serviceType)] = registration
    }
    
    /// Register a singleton instance directly
    func registerInstance<Service>(_ instance: Service) {
        let registration = ServiceRegistration(
            serviceType: Service.self,
            factory: { _ in instance },
            lifetime: .singleton
        )
        registrations[String(describing: Service.self)] = registration
    }
    
    /// Get a service of the specified type
    func resolve<Service>(_ serviceType: Service.Type = Service.self) -> Service? {
        guard let registration = registrations[String(describing: serviceType)] else {
            return nil
        }
        
        return registration.getInstance(from: self) as? Service
    }
    
    /// Get a service of the specified type, throwing an error if not found
    func resolveOrThrow<Service>(_ serviceType: Service.Type = Service.self) throws -> Service {
        guard let service: Service = resolve(serviceType) else {
            throw ServiceError.serviceNotRegistered(String(describing: serviceType))
        }
        return service
    }
}

/// Errors that can occur during service resolution
enum ServiceError: LocalizedError {
    case serviceNotRegistered(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let type):
            return "No service of type '\(type)' has been registered"
        }
    }
} 