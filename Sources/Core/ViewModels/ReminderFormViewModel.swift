import Foundation
import Combine

public class ReminderFormViewModel: BaseFormViewModel {
    // MARK: - Published Properties
    
    @Published public var title: String = ""
    @Published public var notes: String = ""
    @Published public var dueDate: Date = Date()
    @Published public var priority: Int = 1
    
    // MARK: - Private Properties
    
    private var titleSubscription: AnyCancellable?
    private var notesSubscription: AnyCancellable?
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        setupFieldSubscriptions()
    }
    
    // MARK: - Override Methods
    
    public override func setupValidationRules() {
        // Add validation rules for title
        addValidationRule(for: "title", rule: RequiredFieldRule(errorMessage: "Reminder title is required"))
        addValidationRule(for: "title", rule: MinLengthRule(minLength: 3, errorMessage: "Title must be at least 3 characters"))
        
        // Add validation rules for notes (optional)
        addValidationRule(for: "notes", rule: MinLengthRule(minLength: 5, errorMessage: "Notes must be at least 5 characters if provided"))
    }
    
    public override func submitForm() async throws {
        // Validate all fields before submission
        let isTitleValid = validateField("title", value: title)
        let isNotesValid = notes.isEmpty || validateField("notes", value: notes)
        
        guard isTitleValid && isNotesValid else {
            throw ValidationError.invalidField("Please fix the validation errors before submitting")
        }
        
        // TODO: Implement actual form submission logic
        // This is where you would typically save the reminder to your data store
    }
    
    // MARK: - Private Methods
    
    private func setupFieldSubscriptions() {
        // Validate title whenever it changes
        titleSubscription = $title
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateField("title", value: value)
            }
        
        // Validate notes whenever they change
        notesSubscription = $notes
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                if !value.isEmpty {
                    self?.validateField("notes", value: value)
                } else {
                    self?.fieldErrors.value.removeValue(forKey: "notes")
                }
            }
    }
} 