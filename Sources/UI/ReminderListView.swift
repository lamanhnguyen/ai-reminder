import SwiftUI

@available(macOS 11.0, *)
struct ReminderListView: View {
    @EnvironmentObject var reminderManager: ReminderManager
    let list: ReminderList
    @State private var isAddingReminder = false
    
    var body: some View {
        List {
            ForEach(list.reminders) { reminder in
                CalendarReminderRow(reminder: reminder)
            }
            
            Button(action: { isAddingReminder = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("New Reminder")
                }
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isAddingReminder) {
            AddReminderView(isPresented: $isAddingReminder, listId: list.id)
        }
    }
} 