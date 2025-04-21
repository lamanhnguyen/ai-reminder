import Foundation
import Combine

/// Protocol defining the contract for form handling ViewModels
protocol FormViewModel {
    /// The current validation state of the form
    var validationState: ValidationState { get }
    
    /// Publisher for validation state changes
    var validationStatePublisher: Published<ValidationState>.Publisher { get }
    
    /// Dictionary of field validation errors
    var fieldErrors: [String: String] { get }
    
    /// Publisher for field errors
    var fieldErrorsPublisher: Published<[String: String]>.Publisher { get }
    
    /// Whether the form is currently valid
    var isValid: Bool { get }
    
    /// Validate a specific field
    /// - Parameters:
    ///   - field: The name of the field to validate
    ///   - value: The value to validate
    ///   - rules: The validation rules to apply
    /// - Returns: An error message if validation fails, nil otherwise
    func validateField(_ field: String, value: Any?, rules: [ValidationRule]) -> String?
    
    /// Update the validation state and field errors
    /// - Parameters:
    ///   - field: The field being validated
    ///   - error: The validation error message, if any
    func updateValidation(field: String, error: String?)
    
    /// Submit the form
    func submit() async throws
}

/// Represents the current validation state of a form
enum ValidationState {
    /// Initial state before validation
    case idle
    /// Form is currently being validated
    case validating
    /// Form validation succeeded
    case valid
    /// Form validation failed
    case invalid
} 