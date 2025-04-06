import SwiftUI
import AVFoundation

struct AddReminderView: View {
    @Binding var isPresented: Bool
    let listId: UUID
    @EnvironmentObject private var voiceRecognizer: VoiceRecognizer
    @EnvironmentObject private var reminderManager: ReminderManager
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var isRecurring = false
    @State private var recurrenceFrequency: RecurrenceFrequency = .daily
    @State private var isPriority = false
    @State private var isRecording = false
    @State private var showVoiceInput = false
    @FocusState private var isTitleFocused: Bool
    
    private var list: ReminderList? {
        reminderManager.lists.first { $0.id == listId }
    }
    
    var body: some View {
        Form {
            Section {
                // Simple plain TextField with no custom styling
                TextField("Title", text: $title)
                    .focused($isTitleFocused)
                
                TextField("Notes", text: $notes)
            } header: {
                Text("Reminder Details")
            }
            
            Section {
                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
            } header: {
                Text("Due Date")
            }
            
            Section {
                Toggle("Recurring", isOn: $isRecurring)
                if isRecurring {
                    Picker("Frequency", selection: $recurrenceFrequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue.capitalized).tag(frequency)
                        }
                    }
                }
            } header: {
                Text("Recurrence")
            }
            
            Section {
                Toggle("High Priority", isOn: $isPriority)
            } header: {
                Text("Priority")
            }
            
            Section {
                Toggle("Use Voice Input", isOn: $showVoiceInput)
                if showVoiceInput {
                    VoiceInputSection(isRecording: $isRecording, onTextRecognized: { text in
                        title = text
                    })
                }
            } header: {
                Text("Voice Input")
            }
        }
        .navigationTitle(list != nil ? "Add \(list!.name) Reminder" : "Add Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismissView()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveReminder()
                    dismissView()
                }
                .disabled(title.isEmpty)
            }
        }
        .onAppear {
            // Set focus after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                isTitleFocused = true
            }
        }
    }
    
    private func saveReminder() {
        let newReminder = Reminder(
            id: UUID(),
            title: title,
            notes: notes,
            dueDate: dueDate,
            isCompleted: false,
            isRecurring: isRecurring,
            recurrenceFrequency: recurrenceFrequency,
            isPriority: isPriority,
            listId: listId
        )
        reminderManager.addReminder(newReminder, to: listId)
        dismissView()
    }
    
    // Add dedicated methods to handle dismiss with a single approach
    private func dismissView() {
        isPresented = false
        // Don't call dismiss() here - just use binding
    }
}

struct VoiceInputSection: View {
    @EnvironmentObject private var voiceRecognizer: VoiceRecognizer
    @Binding var isRecording: Bool
    var onTextRecognized: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    isRecording.toggle()
                    if isRecording {
                        try? voiceRecognizer.startRecording()
                    } else {
                        voiceRecognizer.stopRecording()
                        if !voiceRecognizer.recognizedText.isEmpty {
                            onTextRecognized(voiceRecognizer.recognizedText)
                        }
                    }
                }) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title)
                        .foregroundColor(isRecording ? .red : .blue)
                }
                
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .foregroundColor(isRecording ? .red : .blue)
            }
            
            if !voiceRecognizer.recognizedText.isEmpty {
                Text("Recognized Text:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(voiceRecognizer.recognizedText)
                    .font(.body)
            }
            
            if let error = voiceRecognizer.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    AddReminderView(isPresented: .constant(true), listId: UUID())
        .environmentObject(ReminderManager())
        .environmentObject(VoiceRecognizer(audioEngine: AVAudioEngine()))
} 
