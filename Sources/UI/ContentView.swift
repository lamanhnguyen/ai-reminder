import SwiftUI
import AVFoundation

// Declare CalendarFilter enum as public so it can be accessed by other files
public enum CalendarFilter {
    case today
    case scheduled
    
    var title: String {
        switch self {
        case .today:
            return "Today"
        case .scheduled:
            return "Scheduled"
        }
    }
    
    var icon: String {
        switch self {
        case .today:
            return "calendar"
        case .scheduled:
            return "calendar.badge.clock"
        }
    }
    
    var color: Color {
        switch self {
        case .today:
            return .blue
        case .scheduled:
            return .red
        }
    }
}

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

@available(macOS 11.0, *)
struct ContentView: View {
    @EnvironmentObject var reminderManager: ReminderManager
    @EnvironmentObject var voiceRecognizer: VoiceRecognizer
    @AppStorage("selectedListId") private var selectedListIdString: String?
    @State private var isAddingList = false
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var calendarFilter: CalendarFilter?
    
    private var selectedListId: UUID? {
        guard let idString = selectedListIdString else { return nil }
        return UUID(uuidString: idString)
    }
    
    private var filteredLists: [ReminderList] {
        guard !searchText.isEmpty else { return reminderManager.lists }
        return reminderManager.lists.filter { list in
            list.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        #if os(iOS)
        NavigationView {
            SidebarView(
                searchText: $searchText,
                isSearching: $isSearching,
                calendarFilter: $calendarFilter,
                isAddingList: $isAddingList,
                selectedListIdString: $selectedListIdString,
                filteredLists: filteredLists
            )
            .navigationBarTitleDisplayMode(.inline)
            
            Group {
                if let filter = calendarFilter {
                    CalendarView(filter: filter)
                } else if let id = selectedListId,
                          let list = reminderManager.lists.first(where: { $0.id == id }) {
                    ReminderListView(list: list)
                } else {
                    VStack {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                            .padding()
                        Text("Select a list")
                            .font(.headline)
                        Text("Choose a reminder list from the sidebar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
                }
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        #else
        Text("MacOS UI not implemented yet")
        #endif
    }
}

@available(macOS 11.0, *)
struct SidebarView: View {
    @EnvironmentObject var reminderManager: ReminderManager
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @Binding var calendarFilter: CalendarFilter?
    @Binding var isAddingList: Bool
    @Binding var selectedListIdString: String?
    let filteredLists: [ReminderList]
    
    private var quickFilters: [(CalendarFilter, String, String, Color)] {
        [
            (.today, "calendar", "Today", Color.blue),
            (.scheduled, "calendar.badge.clock", "Scheduled", Color.red)
        ]
    }
    
    var body: some View {
        List {
            Section {
                ForEach(quickFilters, id: \.1) { filter, icon, title, color in
                    Button {
                        calendarFilter = filter
                        selectedListIdString = nil
                    } label: {
                        QuickFilterRow(
                            icon: icon,
                            title: title,
                            count: getTodayOrScheduledCount(filter: filter),
                            color: color
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Section(header: Text("MY LISTS")) {
                ForEach(filteredLists) { list in
                    Button {
                        selectedListIdString = list.id.uuidString
                        calendarFilter = nil
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet.circle.fill")
                                .foregroundColor(Color(hex: list.color))
                            Text(list.name)
                            Spacer()
                            Text("\(list.reminders.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: { isAddingList = true }) {
                    Label("Add List", systemImage: "plus.circle.fill")
                        .foregroundColor(Color.blue)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Reminders")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isSearching.toggle()
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .overlay(
            Group {
                if isSearching {
                    VStack {
                        TextField("Search", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        Spacer()
                    }
                    .background(Color(.systemBackground))
                    .transition(.move(edge: .top))
                }
            }
        )
        #endif
        .sheet(isPresented: $isAddingList) {
            NavigationView {
                AddListView(isPresented: $isAddingList)
            }
        }
    }
    
    private func getTodayOrScheduledCount(filter: CalendarFilter) -> Int {
        switch filter {
        case .today:
            return reminderManager.getTodayReminders().count
        case .scheduled:
            return reminderManager.getScheduledReminders().count
        }
    }
}

struct QuickFilterRow: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        Label {
            HStack {
                Text(title)
                Spacer()
                Text("\(count)")
                    .foregroundColor(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
        }
    }
}

@available(macOS 11.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ReminderManager())
            .environmentObject(VoiceRecognizer(audioEngine: AVAudioEngine()))
    }
} 
