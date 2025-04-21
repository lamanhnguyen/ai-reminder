import Foundation

/// Helper for registering all app dependencies
public final class DependencyRegistrar {
    private let container: DIContainerProtocol
    
    public init(container: DIContainerProtocol = DIContainer.shared) {
        self.container = container
    }
    
    /// Register all app dependencies
    public func registerDependencies() {
        registerMiddleware()
        registerServices()
        registerViewModels()
    }
    
    // MARK: - Private Registration Methods
    
    private func registerMiddleware() {
        // Register ErrorMiddleware as a shared instance
        container.registerShared(ErrorMiddleware.self, instance: ErrorMiddleware())
    }
    
    private func registerServices() {
        // TODO: Register app services
        // Example:
        // container.register(ReminderServiceProtocol.self) { ReminderService() }
    }
    
    private func registerViewModels() {
        // Register ViewModels
        container.register(ReminderFormViewModel.self) { 
            ReminderFormViewModel()
        }
        
        // TODO: Register other ViewModels as needed
    }
}

// MARK: - App Entry Point Extension

extension DIContainer {
    /// Configure the container with all app dependencies
    public func configure() {
        let registrar = DependencyRegistrar(container: self)
        registrar.registerDependencies()
    }
} 