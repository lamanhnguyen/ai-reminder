import SwiftUI

struct ReminderListView: View {
    @StateObject var viewModel: RemindersViewModel
    @State private var showingSortMenu = false
    @State private var showingDateFilterMenu = false
    @State private var showingPriorityFilterMenu = false
    @State private var isEditMode = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.sortedAndFilteredReminders.isEmpty {
                    EmptyStateView()
                } else {
                    reminderList
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                leadingToolbarItems
                trailingToolbarItems
            }
            .searchable(text: $viewModel.searchText, prompt: "Search reminders")
            .overlay(batchActionOverlay)
        }
        .task {
            await viewModel.loadReminders()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "")
        }
    }
    
    private var reminderList: some View {
        List {
            ForEach(viewModel.sortedAndFilteredReminders) { reminder in
                ReminderRow(reminder: reminder, isSelected: viewModel.selectedReminders.contains(reminder.id))
                    .onTapGesture {
                        if isEditMode {
                            viewModel.toggleSelection(for: reminder)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            Task {
                                await viewModel.toggleCompletion(for: reminder)
                            }
                        } label: {
                            Label(reminder.isCompleted ? "Mark Incomplete" : "Complete",
                                  systemImage: reminder.isCompleted ? "xmark.circle" : "checkmark.circle")
                        }
                        .tint(reminder.isCompleted ? .red : .green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteReminder(reminder)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
    
    private var leadingToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button(isEditMode ? "Done" : "Select") {
                isEditMode.toggle()
                if !isEditMode {
                    viewModel.clearSelection()
                }
            }
        }
    }
    
    private var trailingToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Picker("Sort By", selection: $viewModel.sortOption) {
                    ForEach(RemindersViewModel.SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            
            Menu {
                Button(action: { viewModel.dateFilter = .all }) {
                    Label("All", systemImage: viewModel.dateFilter == .all ? "checkmark" : "")
                }
                Button(action: { viewModel.dateFilter = .today }) {
                    Label("Today", systemImage: viewModel.dateFilter == .today ? "checkmark" : "")
                }
                Button(action: { viewModel.dateFilter = .upcoming }) {
                    Label("Upcoming", systemImage: viewModel.dateFilter == .upcoming ? "checkmark" : "")
                }
                Button(action: { viewModel.dateFilter = .overdue }) {
                    Label("Overdue", systemImage: viewModel.dateFilter == .overdue ? "checkmark" : "")
                }
            } label: {
                Label("Filter", systemImage: "calendar")
            }
            
            Menu {
                Button(action: { viewModel.selectedPriority = nil }) {
                    Label("All", systemImage: viewModel.selectedPriority == nil ? "checkmark" : "")
                }
                ForEach(Reminder.Priority.allCases, id: \.self) { priority in
                    Button(action: { viewModel.selectedPriority = priority }) {
                        Label(priority.rawValue, systemImage: viewModel.selectedPriority == priority ? "checkmark" : "")
                    }
                }
            } label: {
                Label("Priority", systemImage: "flag")
            }
            
            Toggle(isOn: $viewModel.showCompleted) {
                Label("Show Completed", systemImage: "eye")
            }
        }
    }
    
    @ViewBuilder
    private var batchActionOverlay: some View {
        if viewModel.hasSelectedReminders {
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        Task {
                            await viewModel.toggleSelectedCompletion(completed: true)
                        }
                    }) {
                        Label("Complete", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        Task {
                            await viewModel.deleteSelectedReminders()
                        }
                    }) {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}

struct ReminderRow: View {
    let reminder: Reminder
    let isSelected: Bool
    
    var body: some View {
        HStack {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reminder.title)
                        .font(.headline)
                        .strikethrough(reminder.isCompleted)
                    
                    if reminder.priority != .none {
                        Image(systemName: "flag.fill")
                            .foregroundColor(priorityColor)
                    }
                }
                
                if let notes = reminder.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let dueDate = reminder.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var priorityColor: Color {
        switch reminder.priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .yellow
        case .none:
            return .clear
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Reminders")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Add a reminder to get started")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ReminderListView(viewModel: RemindersViewModel(remindersService: PreviewRemindersService()))
} 