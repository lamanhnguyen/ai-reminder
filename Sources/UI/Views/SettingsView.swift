import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var container: DependencyContainer
    
    var body: some View {
        NavigationView {
            Text("Settings")
                .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DependencyContainer())
} 