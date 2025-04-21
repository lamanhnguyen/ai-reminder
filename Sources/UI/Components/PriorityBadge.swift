import SwiftUI

struct PriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        switch priority {
        case .high:
            return Color.red.opacity(0.2)
        case .medium:
            return Color.orange.opacity(0.2)
        case .low:
            return Color.blue.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .blue
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        PriorityBadge(priority: .high)
        PriorityBadge(priority: .medium)
        PriorityBadge(priority: .low)
    }
} 