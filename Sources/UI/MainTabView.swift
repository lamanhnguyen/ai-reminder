import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var container: DependencyContainer
    
    var body: some View {
        TabView {
            RemindersListView()
                .tabItem {
                    Label("Reminders", systemImage: "list.bullet")
                }
            
            CreateReminderView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(DependencyContainer())
} 