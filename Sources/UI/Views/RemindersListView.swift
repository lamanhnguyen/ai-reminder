import SwiftUI

struct RemindersListView: View {
    @EnvironmentObject private var container: DependencyContainer
    
    var body: some View {
        NavigationView {
            Text("Reminders List")
                .navigationTitle("Reminders")
        }
    }
}

#Preview {
    RemindersListView()
        .environmentObject(DependencyContainer())
} 