import SwiftUI
import AVFoundation

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @EnvironmentObject var reminderManager: ReminderManager
    @EnvironmentObject var voiceRecognizer: VoiceRecognizer
    @State private var isAddingList = false
    @State private var isAddingReminder = false
    @State private var selectedListId: UUID?
    @State private var searchText = ""
    
    // To prevent auto-selection infinite loop
    @State private var hasInitialized = false
    
    // Initialize with the selected list from ReminderManager
    init() {
        let savedIdString = UserDefaults.standard.string(forKey: "selectedListId")
        if let idString = savedIdString, let uuid = UUID(uuidString: idString) {
            _selectedListId = State(initialValue: uuid)
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedListId) {
                // Quick filters section
                Section {
                    QuickFilterRow(icon: "calendar", title: "Today", count: 3, color: .blue)
                    QuickFilterRow(icon: "calendar.badge.clock", title: "Scheduled", count: 8, color: .red)
                    QuickFilterRow(icon: "flag", title: "Flagged", count: 0, color: .orange)
                    QuickFilterRow(icon: "checkmark.circle.fill", title: "Completed", count: 0, color: .gray)
                }
                
                // My Lists section
                Section(header: Text("My Lists")) {
                    ForEach(reminderManager.lists) { list in
                        NavigationLink(value: list.id) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: list.color))
                                    .frame(width: 10, height: 10)
                                Text(list.name)
                                Spacer()
                                Text("\(list.reminders.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .id(list.id)
                        .tag(list.id)
                    }
                    Button(action: { isAddingList = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add List")
                        }
                    }
                }
            }
            .onChange(of: selectedListId) { newValue in
                if let listId = newValue {
                    print("Selected list ID: \(listId)")
                    // Save selection to UserDefaults
                    UserDefaults.standard.set(listId.uuidString, forKey: "selectedListId")
                }
            }
            .navigationTitle("Reminders")
            .searchable(text: $searchText, prompt: "Search")
        } detail: {
            if let selectedId = selectedListId,
               reminderManager.lists.contains(where: { $0.id == selectedId }) {
                ListDetailView(listId: selectedId)
                    .id(selectedId) // Ensure view refreshes when selection changes
            } else {
                Text("Select a list")
                    .foregroundColor(.secondary)
                    .onAppear {
                        if !reminderManager.lists.isEmpty && selectedListId == nil && !hasInitialized {
                            hasInitialized = true
                            DispatchQueue.main.async {
                                selectedListId = reminderManager.lists[0].id
                            }
                        }
                    }
            }
        }
        .onAppear {
            // Initialize selection if needed - but only once
            if selectedListId == nil && !reminderManager.lists.isEmpty && !hasInitialized {
                hasInitialized = true
                selectedListId = reminderManager.lists[0].id
                print("Setting initial selection to: \(reminderManager.lists[0].id)")
            }
        }
        .sheet(isPresented: $isAddingList) {
            NavigationView {
                AddListView(isPresented: $isAddingList)
            }
        }
    }
}

struct QuickFilterRow: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ReminderManager())
        .environmentObject(VoiceRecognizer(audioEngine: AVAudioEngine()))
} 