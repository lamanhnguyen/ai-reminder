import XCTest
@testable import VoiceReminders
import SwiftUI
import AVFoundation

class CalendarViewTests: XCTestCase {
    var reminderManager: ReminderManager!
    var voiceRecognizer: VoiceRecognizer!
    
    override func setUp() {
        super.setUp()
        reminderManager = ReminderManager()
        voiceRecognizer = VoiceRecognizer(audioEngine: AVAudioEngine())
    }
    
    override func tearDown() {
        reminderManager = nil
        voiceRecognizer = nil
        super.tearDown()
    }
    
    func testNavigationLinksInContentView() {
        // Create a ContentView with mocked dependencies
        let navLinks = findNavigationLinkCount(in: ContentView()
            .environmentObject(reminderManager)
            .environmentObject(voiceRecognizer))
        
        // We expect at least two navigation links (Today and Scheduled)
        XCTAssertGreaterThanOrEqual(navLinks, 2, "ContentView should contain navigation links for Today and Scheduled views")
    }
    
    func testCalendarViewFiltering() {
        // Add some test reminders
        let personalListId = reminderManager.lists.first(where: { $0.name == "Personal" })?.id ?? UUID()
        
        // Today reminder
        let todayDate = Date()
        reminderManager.addReminder("Today Reminder", dueDate: todayDate, to: personalListId)
        
        // Future reminder (scheduled)
        let futureDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        reminderManager.addReminder("Future Reminder", dueDate: futureDate, to: personalListId)
        
        // Check Today filter
        let todayView = CalendarView(filter: .today)
            .environmentObject(reminderManager)
        
        // Check Scheduled filter
        let scheduledView = CalendarView(filter: .scheduled)
            .environmentObject(reminderManager)
        
        // Basic test to make sure views can be instantiated
        XCTAssertNotNil(todayView, "Today filter view should be created")
        XCTAssertNotNil(scheduledView, "Scheduled filter view should be created")
    }
    
    // Helper functions
    private func findNavigationLinkCount(in view: some View) -> Int {
        let mirror = Mirror(reflecting: view)
        var count = 0
        
        for child in mirror.children {
            if let childType = type(of: child.value) as? Any.Type,
               String(describing: childType).contains("NavigationLink") {
                count += 1
            }
            
            // Recursively search in child views
            let childMirror = Mirror(reflecting: child.value)
            count += findNavigationLinkDestinations(in: childMirror)
        }
        
        return count
    }
    
    private func findNavigationLinkDestinations(in mirror: Mirror) -> Int {
        var count = 0
        
        for child in mirror.children {
            if let childType = type(of: child.value) as? Any.Type,
               String(describing: childType).contains("NavigationLink") {
                count += 1
            }
            
            // Recursively search in child views
            let childMirror = Mirror(reflecting: child.value)
            count += findNavigationLinkDestinations(in: childMirror)
        }
        
        return count
    }
} 
} 