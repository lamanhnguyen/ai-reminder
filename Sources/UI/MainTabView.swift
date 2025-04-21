import SwiftUI

enum Tab: Int {
    case reminders
    case create
    case settings
}

struct MainTabView: View {
    @StateObject private var coordinator = NavigationCoordinator()
    @EnvironmentObject private var container: DependencyContainer
    @State private var selectedTab: Tab = .reminders
    @State private var showNewReminderSheet = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RemindersListView(viewModel: .init(remindersService: container.remindersService))
                .tabItem {
                    Label("Reminders", systemImage: "list.bullet")
                }
                .tag(Tab.reminders)
            
            // Center tab for creating new reminders
            Color.clear
                .tabItem {
                    Label("New", systemImage: "plus.circle.fill")
                }
                .tag(Tab.create)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == .create {
                showNewReminderSheet = true
                // Reset back to previous tab
                selectedTab = coordinator.previousTab ?? .reminders
            }
            coordinator.previousTab = newTab
        }
        .sheet(isPresented: $showNewReminderSheet) {
            CreateReminderView(
                viewModel: .init(
                    remindersService: container.remindersService,
                    voiceRecognitionService: container.voiceRecognitionService
                )
            )
        }
        .environmentObject(coordinator)
        .tint(.blue)
    }
}

// Navigation coordinator to manage app-wide navigation state
final class NavigationCoordinator: ObservableObject {
    @Published var previousTab: Tab?
    @Published var activeSheet: Sheet?
    
    enum Sheet: Identifiable {
        case newReminder
        case reminderDetail(Reminder)
        case settings
        
        var id: String {
            switch self {
            case .newReminder: return "new"
            case .reminderDetail(let reminder): return "detail-\(reminder.id)"
            case .settings: return "settings"
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(DependencyContainer.shared)
} 