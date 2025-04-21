import Foundation
import SwiftUI

// MARK: - Service Protocols

/// Protocol for managing Core Data persistence operations
protocol CoreDataServiceProtocol {
    // Core Data operations will be added here
}

/// Protocol for managing reminders
protocol RemindersServiceProtocol {
    // Reminder operations will be added here
}

/// Protocol for voice recognition capabilities
protocol VoiceRecognitionServiceProtocol {
    // Voice recognition operations will be added here
}

/// Protocol for managing notifications
protocol NotificationServiceProtocol {
    // Notification operations will be added here
}

// MARK: - Service Container

/// Main dependency injection container for the app
final class ServiceContainer: ObservableObject {
    // MARK: - Shared Instance
    
    /// Shared instance for app-wide access
    static let shared = ServiceContainer()
    
    // MARK: - Services
    
    /// Core Data service for persistence operations
    @Published private(set) var coreDataService: CoreDataServiceProtocol!
    
    /// Service for managing reminders
    @Published private(set) var remindersService: RemindersServiceProtocol!
    
    /// Service for voice recognition
    @Published private(set) var voiceRecognitionService: VoiceRecognitionServiceProtocol!
    
    /// Service for managing notifications
    @Published private(set) var notificationService: NotificationServiceProtocol!
    
    // MARK: - Initialization
    
    private init() {
        setupServices()
    }
    
    // MARK: - Setup
    
    /// Sets up all services with their default implementations
    private func setupServices() {
        // Services will be initialized here when implemented
        // This will be called only once when the container is created
    }
    
    // MARK: - Service Registration
    
    /// Registers a Core Data service implementation
    func register(coreDataService: CoreDataServiceProtocol) {
        self.coreDataService = coreDataService
    }
    
    /// Registers a reminders service implementation
    func register(remindersService: RemindersServiceProtocol) {
        self.remindersService = remindersService
    }
    
    /// Registers a voice recognition service implementation
    func register(voiceRecognitionService: VoiceRecognitionServiceProtocol) {
        self.voiceRecognitionService = voiceRecognitionService
    }
    
    /// Registers a notification service implementation
    func register(notificationService: NotificationServiceProtocol) {
        self.notificationService = notificationService
    }
    
    // MARK: - Testing Support
    
    /// Resets all services to nil - useful for testing
    func reset() {
        coreDataService = nil
        remindersService = nil
        voiceRecognitionService = nil
        notificationService = nil
    }
}

// MARK: - Environment Key

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

// MARK: - Environment Values Extension

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Injects the service container into the view hierarchy
    func withServiceContainer(_ container: ServiceContainer = .shared) -> some View {
        environment(\.serviceContainer, container)
    }
} 