import Foundation
import Combine

@MainActor
final class ReminderFormViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var title = ""
    @Published var notes = ""
    @Published var dueDate: Date?
    @Published var priority = ReminderPriority.medium
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // MARK: - Validation
    @Published private(set) var titleError: String?
    
    var isValid: Bool {
        validateTitle()
        return titleError == nil
    }
    
    // MARK: - Private Properties
    private let remindersService: RemindersServiceProtocol
    private let existingReminder: Reminder?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(remindersService: RemindersServiceProtocol, reminder: Reminder? = nil) {
        self.remindersService = remindersService
        self.existingReminder = reminder
        
        if let reminder = reminder {
            title = reminder.title
            notes = reminder.notes ?? ""
            dueDate = reminder.dueDate
            priority = reminder.priority
        }
        
        setupBindings()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        $title
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.validateTitle()
            }
            .store(in: &cancellables)
    }
    
    private func validateTitle() {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            titleError = "Title is required"
        } else if title.count > 100 {
            titleError = "Title must be less than 100 characters"
        } else {
            titleError = nil
        }
    }
    
    // MARK: - Public Methods
    func save() async throws {
        guard isValid else {
            throw ValidationError.invalidForm
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let reminder = Reminder(
            id: existingReminder?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            priority: priority,
            isCompleted: existingReminder?.isCompleted ?? false
        )
        
        do {
            if existingReminder != nil {
                try await remindersService.updateReminder(reminder)
            } else {
                try await remindersService.createReminder(reminder)
            }
            error = nil
        } catch {
            self.error = error
            throw error
        }
    }
    
    func clearForm() {
        title = ""
        notes = ""
        dueDate = nil
        priority = .medium
        error = nil
        titleError = nil
    }
}

// MARK: - Errors
extension ReminderFormViewModel {
    enum ValidationError: LocalizedError {
        case invalidForm
        
        var errorDescription: String? {
            switch self {
            case .invalidForm:
                return "Please fix the errors in the form before saving"
            }
        }
    }
} 