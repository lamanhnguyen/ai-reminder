import Foundation
import SwiftUI

/// A container that manages all service dependencies for the app
@MainActor
final class DependencyContainer: ObservableObject {
    // MARK: - Shared Instance
    static let shared = DependencyContainer()
    
    // MARK: - Services
    private(set) lazy var remindersService: RemindersServiceProtocol = {
        // TODO: Replace with actual implementation when ready
        RemindersService()
    }()
    
    private(set) lazy var coreDataService: CoreDataServiceProtocol = {
        // TODO: Replace with actual implementation when ready
        CoreDataService()
    }()
    
    private(set) lazy var voiceRecognitionService: VoiceRecognitionServiceProtocol = {
        // TODO: Replace with actual implementation when ready
        VoiceRecognitionService()
    }()
    
    private(set) lazy var notificationService: NotificationServiceProtocol = {
        // TODO: Replace with actual implementation when ready
        NotificationService()
    }()
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Testing Support
    static func createForTesting(
        remindersService: RemindersServiceProtocol? = nil,
        coreDataService: CoreDataServiceProtocol? = nil,
        voiceRecognitionService: VoiceRecognitionServiceProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil
    ) -> DependencyContainer {
        let container = DependencyContainer()
        
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
    
    // MARK: - Private Properties for Testing
    private var _remindersService: RemindersServiceProtocol?
    private var _coreDataService: CoreDataServiceProtocol?
    private var _voiceRecognitionService: VoiceRecognitionServiceProtocol?
    private var _notificationService: NotificationServiceProtocol?
} 