import SwiftUI

struct ReminderDetailView: View {
    @ObservedObject var viewModel: ReminderDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Title", text: $viewModel.title)
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 100)
            }
            
            Section(header: Text("Date & Time")) {
                DatePicker("Due Date", selection: $viewModel.dueDate)
            }
            
            Section(header: Text("Priority")) {
                Picker("Priority", selection: $viewModel.priority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
            }
            
            Section {
                Toggle("Completed", isOn: $viewModel.isCompleted)
            }
            
            if !viewModel.isNewReminder {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Created: \(viewModel.createdAtFormatted)")
                        if let updatedAt = viewModel.updatedAtFormatted {
                            Text("Last Modified: \(updatedAt)")
                        }
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(viewModel.isNewReminder ? "New Reminder" : "Edit Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await viewModel.saveReminder()
                        dismiss()
                    }
                }
                .disabled(!viewModel.isValid)
            }
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.error) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

#Preview {
    NavigationView {
        ReminderDetailView(viewModel: ReminderDetailViewModel(
            reminder: nil,
            remindersService: MockRemindersService()
        ))
    }
} 