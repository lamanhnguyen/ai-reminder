import Foundation
import Combine

/// Represents validation errors that can occur in forms
enum ValidationError: LocalizedError {
    case invalidField(String)
    case requiredField(String)
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidField(let field):
            return "\(field) is invalid"
        case .requiredField(let field):
            return "\(field) is required"
        case .custom(let message):
            return message
        }
    }
}

/// Protocol defining a validation rule
protocol ValidationRule {
    associatedtype Value
    func validate(_ value: Value) -> Bool
    var errorMessage: String { get }
}

/// Protocol defining form validation functionality
protocol FormViewModel: ObservableObject {
    var isValid: Bool { get }
    var fieldErrors: [String: String] { get }
    
    func validateField(_ fieldName: String, value: Any) throws
    func addValidationRule<Rule: ValidationRule>(_ rule: Rule, for fieldName: String) where Rule.Value == Any
    func submitForm() async throws
}

/// Base class for form view models providing validation functionality
@MainActor
class BaseFormViewModel: ObservableObject, FormViewModel {
    @Published var isValid: Bool = true
    @Published var fieldErrors: [String: String] = [:]
    
    private var validationRules: [String: [(rule: Any, errorMessage: String)]] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    func addValidationRule<Rule: ValidationRule>(_ rule: Rule, for fieldName: String) where Rule.Value == Any {
        if validationRules[fieldName] == nil {
            validationRules[fieldName] = []
        }
        validationRules[fieldName]?.append((rule, rule.errorMessage))
    }
    
    func validateField(_ fieldName: String, value: Any) throws {
        guard let rules = validationRules[fieldName] else { return }
        
        for (rule, errorMessage) in rules {
            if let typedRule = rule as? any ValidationRule {
                let validates = Mirror(reflecting: typedRule).children.first { $0.label == "validate" }?.value as? ((Any) -> Bool)
                if let validates = validates, !validates(value) {
                    fieldErrors[fieldName] = errorMessage
                    isValid = false
                    throw ValidationError.invalidField(fieldName)
                }
            }
        }
        
        // Clear error if validation passes
        fieldErrors.removeValue(forKey: fieldName)
        isValid = fieldErrors.isEmpty
    }
    
    func submitForm() async throws {
        // Validate all fields before submission
        for (fieldName, _) in validationRules {
            if let error = fieldErrors[fieldName] {
                throw ValidationError.custom(error)
            }
        }
        
        // Base implementation - override in subclasses
        throw ValidationError.custom("submitForm() not implemented")
    }
}

// MARK: - Common Validation Rules

struct RequiredFieldRule<T>: ValidationRule {
    let errorMessage: String
    
    init(fieldName: String) {
        self.errorMessage = "\(fieldName) is required"
    }
    
    func validate(_ value: T) -> Bool {
        if let string = value as? String {
            return !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return value is T
    }
}

struct EmailValidationRule: ValidationRule {
    let errorMessage = "Invalid email format"
    
    func validate(_ value: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: value)
    }
}

struct MinLengthRule: ValidationRule {
    let minLength: Int
    let errorMessage: String
    
    init(minLength: Int, fieldName: String) {
        self.minLength = minLength
        self.errorMessage = "\(fieldName) must be at least \(minLength) characters"
    }
    
    func validate(_ value: String) -> Bool {
        return value.count >= minLength
    }
}

struct RegexValidationRule: ValidationRule {
    let pattern: String
    let errorMessage: String
    
    init(pattern: String, errorMessage: String) {
        self.pattern = pattern
        self.errorMessage = errorMessage
    }
    
    func validate(_ value: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: value)
    }
} 