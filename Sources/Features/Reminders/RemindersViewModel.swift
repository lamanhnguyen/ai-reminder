import Foundation
import Combine

@MainActor
final class RemindersViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var reminders: [Reminder] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // MARK: - Filter States
    @Published var showCompleted = false
    @Published var selectedPriority: ReminderPriority?
    @Published var searchText = ""
    
    // MARK: - Computed Properties
    var filteredReminders: [Reminder] {
        reminders
            .filter { reminder in
                if !showCompleted && reminder.isCompleted {
                    return false
                }
                if let priority = selectedPriority, reminder.priority != priority {
                    return false
                }
                if !searchText.isEmpty {
                    return reminder.title.localizedCaseInsensitiveContains(searchText) ||
                           (reminder.notes ?? "").localizedCaseInsensitiveContains(searchText)
                }
                return true
            }
            .sorted { $0.dueDate ?? .distantFuture < $1.dueDate ?? .distantFuture }
    }
    
    // MARK: - Private Properties
    private let remindersService: RemindersServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(remindersService: RemindersServiceProtocol) {
        self.remindersService = remindersService
        setupBindings()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
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
    func loadReminders() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            reminders = try await remindersService.fetchReminders()
            error = nil
        } catch {
            self.error = error
        }
    }
    
    func addReminder(_ reminder: Reminder) async {
        do {
            try await remindersService.createReminder(reminder)
            error = nil
        } catch {
            self.error = error
        }
    }
    
    func updateReminder(_ reminder: Reminder) async {
        do {
            try await remindersService.updateReminder(reminder)
            error = nil
        } catch {
            self.error = error
        }
    }
    
    func deleteReminder(_ reminder: Reminder) async {
        do {
            try await remindersService.deleteReminder(reminder)
            error = nil
        } catch {
            self.error = error
        }
    }
    
    func deleteAllReminders() async {
        do {
            try await remindersService.deleteAllReminders()
            error = nil
        } catch {
            self.error = error
        }
    }
    
    func toggleCompletion(for reminder: Reminder) async {
        do {
            try await remindersService.toggleReminderCompletion(reminder)
            error = nil
        } catch {
            self.error = error
        }
    }
    
    // MARK: - Filter Methods
    func clearFilters() {
        showCompleted = false
        selectedPriority = nil
        searchText = ""
    }
    
    func filterByPriority(_ priority: ReminderPriority?) {
        selectedPriority = priority
    }
} 