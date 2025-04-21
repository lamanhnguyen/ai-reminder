import SwiftUI

@available(macOS 11.0, *)
struct CalendarView: View {
    @EnvironmentObject var reminderManager: ReminderManager
    let filter: CalendarFilter
    @State private var selectedDate = Date()
    @State private var isAddingReminder = false
    
    var filteredReminders: [Reminder] {
        let allReminders = reminderManager.lists.flatMap { $0.reminders }
        
        switch filter {
        case .today:
            // Get reminders due today
            return allReminders.filter { Calendar.current.isDateInToday($0.dueDate) }
            
        case .scheduled:
            // Get all reminders that are scheduled (have a due date in the future)
            return allReminders.filter { $0.dueDate >= Calendar.current.startOfDay(for: Date()) }
        }
    }
    
    var groupedReminders: [Date: [Reminder]] {
        Dictionary(grouping: filteredReminders) { reminder in
            // Group by start of day for the due date
            Calendar.current.startOfDay(for: reminder.dueDate)
        }
    }
    
    var body: some View {
        List {
            ForEach(groupedReminders.keys.sorted(), id: \.self) { date in
                Section(header: Text(formatDate(date))) {
                    ForEach(groupedReminders[date] ?? []) { reminder in
                        CalendarReminderRow(reminder: reminder)
                    }
                }
            }
            
            if filteredReminders.isEmpty {
                Section {
                    Text("No reminders")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
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
        .navigationTitle(filter.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // This will be called from ContentView so we need to access the environment
                    NotificationCenter.default.post(name: NSNotification.Name("ClearCalendarFilter"), object: nil)
                }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Reset to today
                    selectedDate = Date()
                }) {
                    Image(systemName: "calendar.badge.clock")
                }
            }
        }
        .fullScreenCover(isPresented: $isAddingReminder) {
            if let firstListId = reminderManager.lists.first?.id {
                AddReminderView(isPresented: $isAddingReminder, listId: firstListId)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            return formatter.string(from: date)
        }
    }
}

@available(macOS 11.0, *)
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView(filter: .today)
            .environmentObject(ReminderManager())
    }
}

struct CalendarReminderRow: View {
    @EnvironmentObject var reminderManager: ReminderManager
    let reminder: Reminder
    
    var body: some View {
        HStack {
            Button {
                reminderManager.toggleReminder(reminder, in: reminder.listId)
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
                    // Show time
                    Text(reminder.dueDate.formatted(date: .omitted, time: .shortened))
                    
                    // Show which list it's from
                    let listName = getListName(for: reminder.listId)
                    if !listName.isEmpty {
                        Text("•")
                        Text(listName)
                    }
                    
                    if reminder.isRecurring {
                        Text("•")
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    
                    if reminder.isPriority {
                        Text("•")
                        Image(systemName: "exclamationmark")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Format duration
            if reminder.endDate > reminder.dueDate {
                Text(formatDuration(from: reminder.dueDate, to: reminder.endDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .opacity(reminder.isCompleted ? 0.6 : 1)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                reminderManager.removeReminder(reminder, from: reminder.listId)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func getListName(for listId: UUID) -> String {
        reminderManager.lists.first { $0.id == listId }?.name ?? ""
    }
    
    private func formatDuration(from startDate: Date, to endDate: Date) -> String {
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
} 