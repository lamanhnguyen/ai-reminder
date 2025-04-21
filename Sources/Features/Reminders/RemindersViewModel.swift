import Foundation
import Combine

@MainActor
final class RemindersViewModel: BaseViewModel {
    // MARK: - Types
    enum SortOption: String, CaseIterable {
        case dueDate = "Due Date"
        case priority = "Priority"
        case title = "Title"
        case createdAt = "Created"
    }
    
    enum DateFilter {
        case all
        case today
        case upcoming
        case overdue
        
        var predicate: (Reminder) -> Bool {
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            return { reminder in
                guard let dueDate = reminder.dueDate else { return false }
                switch self {
                case .all:
                    return true
                case .today:
                    return dueDate >= startOfDay && dueDate < endOfDay
                case .upcoming:
                    return dueDate >= endOfDay
                case .overdue:
                    return dueDate < startOfDay && !reminder.isCompleted
                }
            }
        }
    }
    
    // MARK: - Dependencies
    let remindersService: RemindersServiceProtocol
    
    // MARK: - Published Properties
    @Published private(set) var reminders: [Reminder] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var searchText = ""
    @Published var showCompleted = false
    @Published var selectedPriority: Reminder.Priority?
    @Published var sortOption: SortOption = .dueDate
    @Published var dateFilter: DateFilter = .all
    @Published var selectedReminders: Set<UUID> = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(remindersService: RemindersServiceProtocol) {
        self.remindersService = remindersService
        super.init()
        setupBindings()
    }
    
    // MARK: - Public Methods
    func loadReminders() async {
        do {
            isLoading = true
            reminders = try await remindersService.fetchReminders()
        } catch {
            self.error = error
        }
        isLoading = false
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
            reminders.removeAll { $0.id == reminder.id }
            selectedReminders.remove(reminder.id)
        } catch {
            self.error = error
        }
    }
    
    func deleteSelectedReminders() async {
        for id in selectedReminders {
            if let reminder = reminders.first(where: { $0.id == id }) {
                await deleteReminder(reminder)
            }
        }
        selectedReminders.removeAll()
    }
    
    func toggleCompletion(for reminder: Reminder) async {
        do {
            var updatedReminder = reminder
            updatedReminder.isCompleted.toggle()
            try await remindersService.updateReminder(updatedReminder)
            if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                reminders[index] = updatedReminder
            }
        } catch {
            self.error = error
        }
    }
    
    func toggleSelectedCompletion(completed: Bool) async {
        for id in selectedReminders {
            if var reminder = reminders.first(where: { $0.id == id }) {
                reminder.isCompleted = completed
                await updateReminder(reminder)
            }
        }
        selectedReminders.removeAll()
    }
    
    // MARK: - Computed Properties
    var sortedAndFilteredReminders: [Reminder] {
        let filtered = reminders
            .filter { reminder in
                let matchesSearch = searchText.isEmpty || 
                    reminder.title.localizedCaseInsensitiveContains(searchText) ||
                    reminder.notes?.localizedCaseInsensitiveContains(searchText) ?? false
                let matchesCompletion = showCompleted || !reminder.isCompleted
                let matchesPriority = selectedPriority == nil || reminder.priority == selectedPriority
                let matchesDateFilter = dateFilter.predicate(reminder)
                return matchesSearch && matchesCompletion && matchesPriority && matchesDateFilter
            }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .dueDate:
                return (first.dueDate ?? .distantFuture) < (second.dueDate ?? .distantFuture)
            case .priority:
                return first.priority.rawValue > second.priority.rawValue
            case .title:
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            case .createdAt:
                return first.createdAt < second.createdAt
            }
        }
    }
    
    var hasSelectedReminders: Bool {
        !selectedReminders.isEmpty
    }
    
    // MARK: - Selection Methods
    func toggleSelection(for reminder: Reminder) {
        if selectedReminders.contains(reminder.id) {
            selectedReminders.remove(reminder.id)
        } else {
            selectedReminders.insert(reminder.id)
        }
    }
    
    func clearSelection() {
        selectedReminders.removeAll()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        remindersService.remindersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedReminders in
                self?.reminders = updatedReminders
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Filter Methods
    func clearFilters() {
        showCompleted = false
        selectedPriority = nil
        searchText = ""
        dateFilter = .all
    }
    
    func filterByPriority(_ priority: Reminder.Priority?) {
        selectedPriority = priority
    }
}

// MARK: - Preview Helper
class PreviewRemindersService: RemindersServiceProtocol {
    var remindersPublisher: AnyPublisher<[Reminder], Never> {
        Just(previewReminders).eraseToAnyPublisher()
    }
    
    private let previewReminders = [
        Reminder(id: UUID(), title: "Buy groceries", notes: "Milk, eggs, bread", dueDate: Date().addingTimeInterval(3600), priority: .medium, isCompleted: false),
        Reminder(id: UUID(), title: "Call mom", notes: nil, dueDate: Date().addingTimeInterval(7200), priority: .high, isCompleted: false),
        Reminder(id: UUID(), title: "Take out trash", notes: nil, dueDate: Date().addingTimeInterval(-3600), priority: .low, isCompleted: true)
    ]
    
    func createReminder(_ reminder: Reminder) async throws -> Reminder {
        reminder
    }
    
    func updateReminder(_ reminder: Reminder) async throws {
        // No-op for preview
    }
    
    func deleteReminder(_ reminder: Reminder) async throws {
        // No-op for preview
    }
    
    func fetchReminders() async throws -> [Reminder] {
        previewReminders
    }
} 