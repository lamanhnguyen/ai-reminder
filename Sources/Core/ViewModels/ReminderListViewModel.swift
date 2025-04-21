import Foundation
import Combine

/// View model for managing a list of reminders
@MainActor
public final class ReminderListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// The current list of reminders
    @Published private(set) var reminders: [Reminder] = []
    
    /// Loading state
    @Published private(set) var isLoading = false
    
    /// Error state
    @Published var error: Error?
    
    /// Filter for completed/incomplete reminders
    @Published var showCompleted = false
    
    /// Search text for filtering reminders
    @Published var searchText = ""
    
    // MARK: - Dependencies
    
    private let remindersService: RemindersServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Filtered and sorted reminders based on current filter settings
    public var filteredReminders: [Reminder] {
        reminders
            .filter { reminder in
                // Filter by completion status
                reminder.isCompleted == showCompleted &&
                // Filter by search text
                (searchText.isEmpty ||
                 reminder.title.localizedCaseInsensitiveContains(searchText) ||
                 (reminder.notes?.localizedCaseInsensitiveContains(searchText) ?? false))
            }
            .sorted { first, second in
                // Sort by priority first
                if first.priority != second.priority {
                    return first.priority.rawValue > second.priority.rawValue
                }
                // Then by due date
                return first.dueDate < second.dueDate
            }
    }
    
    // MARK: - Initialization
    
    public init(remindersService: RemindersServiceProtocol) {
        self.remindersService = remindersService
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Subscribe to reminders updates from the service
        remindersService.remindersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] reminders in
                self?.reminders = reminders
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Refresh the reminders list
    public func refreshReminders() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let reminders = try await remindersService.getAllReminders()
            self.reminders = reminders
            error = nil
        } catch {
            self.error = error
        }
    }
    
    /// Toggle the completion status of a reminder
    public func toggleCompletion(for reminder: Reminder) async {
        do {
            try await remindersService.markReminderCompleted(reminder, completed: !reminder.isCompleted)
            error = nil
        } catch {
            self.error = error
        }
    }
    
    /// Delete a reminder
    public func deleteReminder(_ reminder: Reminder) async {
        do {
            try await remindersService.deleteReminder(reminder)
            error = nil
        } catch {
            self.error = error
        }
    }
    
    /// Clear the current error
    public func clearError() {
        error = nil
    }
} 