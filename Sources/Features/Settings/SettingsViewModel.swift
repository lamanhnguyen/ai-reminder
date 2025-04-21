import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: BaseViewModelImpl {
    // MARK: - Dependencies
    private let notificationService: NotificationServiceProtocol
    private let voiceRecognitionService: VoiceRecognitionServiceProtocol
    
    // MARK: - Published Properties
    @Published var isNotificationsEnabled = false
    @Published var isSpeechRecognitionEnabled = false
    
    // MARK: - Initialization
    init(container: DependencyContainer = .shared) {
        self.notificationService = container.notificationService
        self.voiceRecognitionService = container.voiceRecognitionService
        super.init()
        Task {
            await loadSettings()
        }
    }
    
    // MARK: - Public Methods
    func requestNotificationPermission() async {
        isLoading = true
        do {
            let granted = try await notificationService.requestAuthorization(options: [.alert, .sound, .badge])
            isNotificationsEnabled = granted
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    func requestSpeechRecognitionPermission() async {
        isLoading = true
        do {
            try await voiceRecognitionService.requestAuthorization()
            isSpeechRecognitionEnabled = voiceRecognitionService.isAvailable
        } catch {
            handleError(error)
        }
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func loadSettings() async {
        isLoading = true
        do {
            let notificationStatus = await notificationService.authorizationStatus
            isNotificationsEnabled = notificationStatus == .authorized
            
            isSpeechRecognitionEnabled = voiceRecognitionService.isAvailable
        } catch {
            handleError(error)
        }
        isLoading = false
    }
} 