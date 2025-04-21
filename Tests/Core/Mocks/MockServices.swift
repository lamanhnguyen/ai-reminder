import Foundation
@testable import VoiceReminders

// MARK: - Mock Core Data Service

final class MockCoreDataService: CoreDataServiceProtocol {
    var saveContextCalled = false
    var loadDataCalled = false
    
    func saveContext() {
        saveContextCalled = true
    }
    
    func loadData() {
        loadDataCalled = true
    }
}

// MARK: - Mock Reminders Service

final class MockRemindersService: RemindersServiceProtocol {
    var createReminderCalled = false
    var updateReminderCalled = false
    var deleteReminderCalled = false
    var fetchRemindersCalled = false
    
    var reminders: [Reminder] = []
    var error: Error?
    
    func createReminder(_ reminder: Reminder) throws {
        createReminderCalled = true
        if let error = error {
            throw error
        }
        reminders.append(reminder)
    }
    
    func updateReminder(_ reminder: Reminder) throws {
        updateReminderCalled = true
        if let error = error {
            throw error
        }
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
        }
    }
    
    func deleteReminder(_ reminder: Reminder) throws {
        deleteReminderCalled = true
        if let error = error {
            throw error
        }
        reminders.removeAll { $0.id == reminder.id }
    }
    
    func fetchReminders() throws -> [Reminder] {
        fetchRemindersCalled = true
        if let error = error {
            throw error
        }
        return reminders
    }
}

// MARK: - Mock Voice Recognition Service

final class MockVoiceRecognitionService: VoiceRecognitionServiceProtocol {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var isRecording = false
    var recognizedText: String?
    var error: Error?
    
    func startRecording() throws {
        startRecordingCalled = true
        if let error = error {
            throw error
        }
        isRecording = true
    }
    
    func stopRecording() throws -> String {
        stopRecordingCalled = true
        if let error = error {
            throw error
        }
        isRecording = false
        return recognizedText ?? ""
    }
}

// MARK: - Mock Notification Service

final class MockNotificationService: NotificationServiceProtocol {
    var scheduleNotificationCalled = false
    var cancelNotificationCalled = false
    var requestPermissionsCalled = false
    var error: Error?
    
    func scheduleNotification(for reminder: Reminder) throws {
        scheduleNotificationCalled = true
        if let error = error {
            throw error
        }
    }
    
    func cancelNotification(for reminder: Reminder) throws {
        cancelNotificationCalled = true
        if let error = error {
            throw error
        }
    }
    
    func requestPermissions() async throws {
        requestPermissionsCalled = true
        if let error = error {
            throw error
        }
    }
} 