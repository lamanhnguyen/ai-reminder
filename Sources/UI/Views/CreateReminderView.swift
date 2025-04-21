import SwiftUI

struct CreateReminderView: View {
    @EnvironmentObject private var container: DependencyContainer
    
    var body: some View {
        NavigationView {
            Text("Create Reminder")
                .navigationTitle("New Reminder")
        }
    }
}

#Preview {
    CreateReminderView()
        .environmentObject(DependencyContainer())
} 