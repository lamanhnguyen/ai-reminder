import Foundation
import CoreData
import Speech
import UserNotifications
import Combine

// MARK: - Core Data Service Protocol

/// Protocol for managing Core Data operations
protocol CoreDataServiceProtocol {
    /// The main view context for Core Data operations
    var viewContext: NSManagedObjectContext { get }
    
    /// Save changes to Core Data
    func saveContext() throws
    
    /// Create a new background context
    func newBackgroundContext() -> NSManagedObjectContext
}

// MARK: - Reminders Service Protocol

/// Protocol for managing reminders
protocol RemindersServiceProtocol {
    /// Fetch all reminders
    func fetchReminders() async throws -> [Reminder]
    
    /// Create a new reminder
    func createReminder(title: String, notes: String?, dueDate: Date?, priority: ReminderPriority) async throws -> Reminder
    
    /// Update an existing reminder
    func updateReminder(_ reminder: Reminder) async throws
    
    /// Delete a reminder
    func deleteReminder(_ reminder: Reminder) async throws
    
    /// Mark a reminder as completed
    func completeReminder(_ reminder: Reminder) async throws
    
    /// Search for reminders
    func searchReminders(query: String) async throws -> [Reminder]
}

// MARK: - Voice Recognition Service Protocol

/// Protocol for voice recognition capabilities
protocol VoiceRecognitionServiceProtocol {
    /// Check if voice recognition is available
    var isVoiceRecognitionAvailable: Bool { get }
    
    /// Request necessary permissions for voice recognition
    func requestPermissions() async throws
    
    /// Start voice recognition
    func startRecognition() async throws
    
    /// Stop voice recognition
    func stopRecognition() async throws
    
    /// Get the current recognition status
    var recognitionStatus: SFSpeechRecognizerAuthorizationStatus { get }
    
    /// Publisher for real-time transcription results
    var transcriptionPublisher: AnyPublisher<String, Error> { get }
}

// MARK: - Notification Service Protocol

/// Protocol for managing notifications
protocol NotificationServiceProtocol {
    /// Request notification permissions
    func requestPermissions() async throws
    
    /// Schedule a notification for a reminder
    func scheduleNotification(for reminder: Reminder) async throws
    
    /// Cancel notifications for a reminder
    func cancelNotifications(for reminder: Reminder) async throws
    
    /// Cancel all scheduled notifications
    func cancelAllNotifications() async throws
    
    /// Handle notification response
    func handleNotificationResponse(_ response: UNNotificationResponse) async
}

/// Protocol for managing app settings
protocol SettingsServiceProtocol {
    /// Get a setting value
    func getValue<T>(for key: String) -> T?
    
    /// Set a setting value
    func setValue<T>(_ value: T, for key: String)
    
    /// Reset all settings to defaults
    func resetToDefaults()
    
    /// Publisher for setting changes
    var settingsChangedPublisher: AnyPublisher<String, Never> { get }
} 