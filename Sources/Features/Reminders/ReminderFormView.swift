import SwiftUI

struct ReminderFormView: View {
    @StateObject private var viewModel = ReminderFormViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $viewModel.title)
                        .textInputAutocapitalization(.sentences)
                    
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Due Date")) {
                    DatePicker("Due Date", selection: $viewModel.dueDate)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $viewModel.priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized)
                                .tag(priority)
                        }
                    }
                }
            }
            .navigationTitle("New Reminder")
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
                            do {
                                try await viewModel.save()
                                dismiss()
                            } catch {
                                // Error is handled by the view model
                            }
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil), actions: {
                Button("OK") {
                    viewModel.clearError()
                }
            }, message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            })
        }
    }
} 