import Foundation

/// Configures all services in the application
final class ServiceConfiguration {
    /// Configure all services in the container
    static func configure(_ container: ServiceContainer) {
        // Core Services
        container.register(CoreDataServiceProtocol.self, implementation: CoreDataService.self, lifetime: .singleton)
        container.register(NotificationServiceProtocol.self, implementation: NotificationService.self, lifetime: .singleton)
        
        // Business Services
        container.register(RemindersServiceProtocol.self) { container in
            let coreDataService = try! container.resolveOrThrow(CoreDataServiceProtocol.self)
            let notificationService = try! container.resolveOrThrow(NotificationServiceProtocol.self)
            return RemindersService(coreDataService: coreDataService, notificationService: notificationService)
        }
        
        // View Models
        container.register(ReminderListViewModel.self) { container in
            let remindersService = try! container.resolveOrThrow(RemindersServiceProtocol.self)
            return ReminderListViewModel(remindersService: remindersService)
        }
        
        container.register(ReminderFormViewModel.self) { container in
            let remindersService = try! container.resolveOrThrow(RemindersServiceProtocol.self)
            return ReminderFormViewModel(remindersService: remindersService)
        }
        
        // Error Handling
        container.registerInstance(ErrorMiddleware())
    }
}

/// Extension to ServiceContainer for easy access to common services
extension ServiceContainer {
    /// Get the reminders service
    var remindersService: RemindersServiceProtocol {
        get throws { try resolveOrThrow(RemindersServiceProtocol.self) }
    }
    
    /// Get the error middleware
    var errorMiddleware: ErrorMiddleware {
        get throws { try resolveOrThrow(ErrorMiddleware.self) }
    }
    
    /// Get the notification service
    var notificationService: NotificationServiceProtocol {
        get throws { try resolveOrThrow(NotificationServiceProtocol.self) }
    }
    
    /// Get the core data service
    var coreDataService: CoreDataServiceProtocol {
        get throws { try resolveOrThrow(CoreDataServiceProtocol.self) }
    }
} 