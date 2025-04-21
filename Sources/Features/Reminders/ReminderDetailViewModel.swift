import Foundation
import Combine

@MainActor
final class ReminderDetailViewModel: ObservableObject {
    private let remindersService: RemindersServiceProtocol
    private let reminder: Reminder?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var title: String = ""
    @Published var notes: String = ""
    @Published var dueDate: Date = Date()
    @Published var priority: Priority = .medium
    @Published var isCompleted: Bool = false
    @Published var error: Error?
    @Published var showError: Bool = false
    
    var isNewReminder: Bool { reminder == nil }
    var isValid: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    var createdAtFormatted: String {
        DateFormatter.mediumDateTime.string(from: reminder?.createdAt ?? Date())
    }
    
    var updatedAtFormatted: String? {
        guard let updatedAt = reminder?.updatedAt else { return nil }
        return DateFormatter.mediumDateTime.string(from: updatedAt)
    }
    
    init(reminder: Reminder?, remindersService: RemindersServiceProtocol) {
        self.reminder = reminder
        self.remindersService = remindersService
        
        if let reminder = reminder {
            self.title = reminder.title
            self.notes = reminder.notes ?? ""
            self.dueDate = reminder.dueDate
            self.priority = reminder.priority
            self.isCompleted = reminder.isCompleted
        }
    }
    
    func saveReminder() async {
        do {
            let updatedReminder = Reminder(
                id: reminder?.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.isEmpty ? nil : notes,
                dueDate: dueDate,
                priority: priority,
                isCompleted: isCompleted,
                createdAt: reminder?.createdAt ?? Date(),
                updatedAt: Date()
            )
            
            if isNewReminder {
                try await remindersService.createReminder(updatedReminder)
            } else {
                try await remindersService.updateReminder(updatedReminder)
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }
}

private extension DateFormatter {
    static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
} 