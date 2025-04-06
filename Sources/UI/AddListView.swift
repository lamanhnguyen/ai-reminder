import SwiftUI

struct AddListView: View {
    @EnvironmentObject var reminderManager: ReminderManager
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var selectedColor = "#FF6B6B"
    
    let colors = [
        "#FF6B6B", // Red
        "#4ECDC4", // Teal
        "#45B7D1", // Blue
        "#96CEB4", // Green
        "#FFEEAD", // Yellow
        "#D4A5A5", // Pink
        "#9B59B6", // Purple
        "#3498DB"  // Dark Blue
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("List Name", text: $name)
                }
                
                Section("Color") {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 44))
                    ], spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if color == selectedColor {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New List")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Add") {
                    reminderManager.createList(name: name, color: selectedColor)
                    isPresented = false
                }
                .disabled(name.isEmpty)
            )
        }
    }
}

#Preview {
    AddListView(isPresented: .constant(true))
        .environmentObject(ReminderManager())
} 