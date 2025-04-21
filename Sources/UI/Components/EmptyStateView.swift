import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var action: (() -> Void)?
    var actionTitle: String?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    EmptyStateView(
        title: "No Reminders",
        message: "You don't have any reminders yet. Tap the + button to create one.",
        systemImage: "bell.badge",
        action: {},
        actionTitle: "Create Reminder"
    )
} 