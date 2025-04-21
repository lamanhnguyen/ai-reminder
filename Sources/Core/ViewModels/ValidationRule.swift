import Foundation

/// Protocol defining a validation rule
protocol ValidationRule {
    /// Validate a value against this rule
    /// - Parameter value: The value to validate
    /// - Returns: An error message if validation fails, nil otherwise
    func validate(_ value: Any?) -> String?
}

/// Rule that checks if a value is not empty
struct RequiredRule: ValidationRule {
    let message: String
    
    init(message: String = "This field is required") {
        self.message = message
    }
    
    func validate(_ value: Any?) -> String? {
        guard let value = value else { return message }
        
        if let string = value as? String {
            return string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? message : nil
        }
        
        return nil
    }
}

/// Rule that validates minimum length
struct MinLengthRule: ValidationRule {
    let length: Int
    let message: String
    
    init(length: Int, message: String? = nil) {
        self.length = length
        self.message = message ?? "Must be at least \(length) characters"
    }
    
    func validate(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        return string.count < length ? message : nil
    }
}

/// Rule that validates maximum length
struct MaxLengthRule: ValidationRule {
    let length: Int
    let message: String
    
    init(length: Int, message: String? = nil) {
        self.length = length
        self.message = message ?? "Must not exceed \(length) characters"
    }
    
    func validate(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        return string.count > length ? message : nil
    }
}

/// Rule that validates email format
struct EmailRule: ValidationRule {
    let message: String
    
    init(message: String = "Please enter a valid email address") {
        self.message = message
    }
    
    func validate(_ value: Any?) -> String? {
        guard let email = value as? String else { return nil }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email) ? nil : message
    }
}

/// Rule that validates against a regular expression pattern
struct PatternRule: ValidationRule {
    let pattern: String
    let message: String
    
    init(pattern: String, message: String) {
        self.pattern = pattern
        self.message = message
    }
    
    func validate(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        
        let predicate = NSPredicate(format:"SELF MATCHES %@", pattern)
        return predicate.evaluate(with: string) ? nil : message
    }
} 