import SwiftUI
import UserNotifications
import AVFoundation

@main
struct VoiceRemindersApp: App {
    @StateObject private var reminderManager = ReminderManager()
    @StateObject private var voiceRecognizer = VoiceRecognizer(audioEngine: AVAudioEngine())
    
    init() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(reminderManager)
                .environmentObject(voiceRecognizer)
        }
    }
} 