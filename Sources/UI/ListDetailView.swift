import SwiftUI

struct ListDetailView: View {
    @EnvironmentObject var reminderManager: ReminderManager
    let listId: UUID
    @State private var isAddingReminder = false
    @State private var showCompleted = true
    
    var list: ReminderList? {
        reminderManager.lists.first { $0.id == listId }
    }
    
    var incompleteReminders: [Reminder] {
        list?.reminders.filter { !$0.isCompleted } ?? []
    }
    
    var completedReminders: [Reminder] {
        list?.reminders.filter { $0.isCompleted } ?? []
    }
    
    var body: some View {
        List {
            if !incompleteReminders.isEmpty {
                Section {
                    ForEach(incompleteReminders) { reminder in
                        ReminderRow(reminder: reminder, listId: listId)
                    }
                }
            }
            
            if !completedReminders.isEmpty {
                Section {
                    DisclosureGroup(
                        isExpanded: $showCompleted,
                        content: {
                            ForEach(completedReminders) { reminder in
                                ReminderRow(reminder: reminder, listId: listId)
                            }
                        },
                        label: {
                            Text("Completed")
                                .foregroundColor(.secondary)
                        }
                    )
                }
            }
            
            Button(action: { isAddingReminder = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("New Reminder")
                }
            }
        }
        .navigationTitle(list?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isAddingReminder) {
            AddReminderView(isPresented: $isAddingReminder, listId: listId)
        }
    }
}

struct ReminderRow: View {
    @EnvironmentObject var reminderManager: ReminderManager
    let reminder: Reminder
    let listId: UUID
    
    var body: some View {
        HStack {
            Button {
                reminderManager.toggleReminder(reminder, in: listId)
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(reminder.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .strikethrough(reminder.isCompleted)
                
                if !reminder.notes.isEmpty {
                    Text(reminder.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(.red)
                    Text(reminder.dueDate.formatted(date: .abbreviated, time: .shortened))
                    
                    if reminder.isRecurring {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                        Text(reminder.recurrenceFrequency.rawValue)
                    }
                    
                    if reminder.isPriority {
                        Image(systemName: "exclamationmark")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !reminder.isCompleted {
                Button {
                    // Toggle flag
                } label: {
                    Image(systemName: "flag")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                reminderManager.removeReminder(reminder, from: listId)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .opacity(reminder.isCompleted ? 0.6 : 1)
    }
}

#Preview {
    NavigationView {
        ListDetailView(listId: UUID())
            .environmentObject(ReminderManager())
    }
} 