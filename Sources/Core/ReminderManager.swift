import Foundation
import UserNotifications
import SwiftUI

class ReminderManager: ObservableObject {
    @Published var lists: [ReminderList] = []
    @Published var selectedListId: UUID?
    private let userNotificationCenter = UNUserNotificationCenter.current()
    
    init() {
        print("ReminderManager initialized")
        loadLists()
        if lists.isEmpty {
            print("Creating default lists")
            // Create default lists
            createList(name: "Personal", color: "#FF6B6B")
            createList(name: "Work", color: "#4ECDC4")
            createList(name: "Shopping", color: "#45B7D1")
        }
        print("ReminderManager lists count: \(lists.count)")
    }
    
    private func loadLists() {
        print("Loading lists from UserDefaults")
        if let data = UserDefaults.standard.data(forKey: "reminderLists"),
           let decoded = try? JSONDecoder().decode([ReminderList].self, from: data) {
            lists = decoded
            if let firstListId = lists.first?.id {
                selectedListId = firstListId
            }
            print("Loaded \(lists.count) lists from UserDefaults")
        } else {
            print("No lists found in UserDefaults")
        }
    }
    
    private func saveLists() {
        print("Saving lists to UserDefaults")
        if let encoded = try? JSONEncoder().encode(lists) {
            UserDefaults.standard.set(encoded, forKey: "reminderLists")
            print("Successfully saved \(lists.count) lists")
        } else {
            print("Failed to encode lists")
        }
    }
    
    func createList(name: String, color: String) {
        print("Creating new list: \(name)")
        let newList = ReminderList(name: name, color: color)
        lists.append(newList)
        if selectedListId == nil {
            selectedListId = newList.id
        }
        saveLists()
    }
    
    func deleteList(_ list: ReminderList) {
        print("Deleting list: \(list.name)")
        lists.removeAll { $0.id == list.id }
        if selectedListId == list.id {
            selectedListId = lists.first?.id
        }
        saveLists()
    }
    
    func addReminder(_ title: String, dueDate: Date, to listId: UUID) {
        print("Adding reminder: \(title) to list \(listId)")
        guard let index = lists.firstIndex(where: { $0.id == listId }) else { 
            print("Failed to find list with ID: \(listId)")
            return 
        }
        let reminder = Reminder(title: title, dueDate: dueDate, listId: listId)
        lists[index].reminders.append(reminder)
        scheduleNotification(for: reminder)
        saveLists()
    }
    
    func addReminder(_ reminder: Reminder, to listId: UUID) {
        print("Adding detailed reminder: \(reminder.title) to list \(listId)")
        guard let index = lists.firstIndex(where: { $0.id == listId }) else { 
            print("Failed to find list with ID: \(listId)")
            return 
        }
        lists[index].reminders.append(reminder)
        scheduleNotification(for: reminder)
        saveLists()
    }
    
    private func scheduleNotification(for reminder: Reminder) {
        print("Scheduling notification for reminder: \(reminder.title)")
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = reminder.title
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        userNotificationCenter.add(request)
    }
    
    func removeReminder(_ reminder: Reminder, from listId: UUID) {
        print("Removing reminder: \(reminder.title) from list \(listId)")
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }) else { return }
        lists[listIndex].reminders.removeAll { $0.id == reminder.id }
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        saveLists()
    }
    
    func toggleReminder(_ reminder: Reminder, in listId: UUID) {
        print("Toggling reminder: \(reminder.title) in list \(listId)")
        guard let listIndex = lists.firstIndex(where: { $0.id == listId }),
              let reminderIndex = lists[listIndex].reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        
        lists[listIndex].reminders[reminderIndex].isCompleted.toggle()
        saveLists()
    }
    
    func selectedList() -> ReminderList? {
        return lists.first { $0.id == selectedListId }
    }
} 