import SwiftUI
import AVFoundation

struct AddReminderView: View {
    @Binding var isPresented: Bool
    let listId: UUID
    let initialDate: Date
    @EnvironmentObject private var reminderManager: ReminderManager
    @Environment(\.dismiss) private var dismiss
    
    // Form fields with proper validation
    @State private var title = ""
    @State private var notes = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var isRecurring = false
    @State private var priorityLevel = 3
    @State private var recurrenceFrequency: RecurrenceFrequency = .daily
    @State private var plannedStartDate: Date?
    @State private var plannedEndDate: Date?
    @FocusState private var titleFieldIsFocused: Bool
    
    // Validation state
    @State private var showTitleError = false
    @State private var showDateError = false
    
    init(isPresented: Binding<Bool>, listId: UUID, initialDate: Date = Date()) {
        self._isPresented = isPresented
        self.listId = listId
        self.initialDate = initialDate
        _startDate = State(initialValue: initialDate)
        _endDate = State(initialValue: initialDate.addingTimeInterval(3600)) // Default 1 hour duration
    }
    
    private var isSaveEnabled: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        endDate >= startDate
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    // Title field with validation
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("What do you want to remember?", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($titleFieldIsFocused)
                            .onChange(of: title) { newValue in
                                showTitleError = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            }
                            .submitLabel(.next)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textContentType(nil)
                        
                        if showTitleError {
                            Text("Title is required")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Notes field
                    TextField("Add notes", text: $notes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Date & Time")) {
                    DatePicker("Due Date", selection: $startDate)
                    DatePicker("End Date", selection: $endDate)
                    
                    if showDateError {
                        Text("End date must be after start date")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Toggle("Add Planned Dates", isOn: Binding(
                        get: { plannedStartDate != nil },
                        set: { if $0 { 
                            plannedStartDate = startDate
                            plannedEndDate = endDate 
                        } else {
                            plannedStartDate = nil
                            plannedEndDate = nil
                        }}
                    ))
                    
                    if plannedStartDate != nil {
                        DatePicker("Planned Start", selection: Binding(
                            get: { plannedStartDate ?? startDate },
                            set: { plannedStartDate = $0 }
                        ))
                        DatePicker("Planned End", selection: Binding(
                            get: { plannedEndDate ?? endDate },
                            set: { plannedEndDate = $0 }
                        ))
                    }
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority Level", selection: $priorityLevel) {
                        Text("Highest").tag(1)
                        Text("High").tag(2)
                        Text("Medium").tag(3)
                        Text("Low").tag(4)
                        Text("Lowest").tag(5)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Options")) {
                    Toggle("Recurring", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Frequency", selection: $recurrenceFrequency) {
                            ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.rawValue.capitalized)
                                    .tag(frequency)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .disabled(!isSaveEnabled)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                titleFieldIsFocused = true
            }
        }
    }
    
    private func saveReminder() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        // Validate dates
        if endDate < startDate {
            showDateError = true
            return
        }
        
        let reminder = Reminder(
            id: UUID(),
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: startDate,
            endDate: endDate,
            isCompleted: false,
            isRecurring: isRecurring,
            recurrenceFrequency: recurrenceFrequency,
            priorityLevel: priorityLevel,
            plannedStartDate: plannedStartDate,
            plannedEndDate: plannedEndDate,
            listId: listId
        )
        
        reminderManager.addReminder(reminder, to: listId)
        dismiss()
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
