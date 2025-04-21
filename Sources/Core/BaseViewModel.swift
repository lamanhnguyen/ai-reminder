import Foundation
import SwiftUI

/// A protocol that defines common functionality for all view models
protocol BaseViewModel: ObservableObject {
    /// Indicates whether the view model is currently loading data
    var isLoading: Bool { get set }
    
    /// The current error state of the view model, if any
    var error: Error? { get set }
    
    /// Reset the view model's error state
    func clearError()
    
    /// Handle and store an error that occurred during view model operations
    func handleError(_ error: Error)
}

/// Default implementation of BaseViewModel
extension BaseViewModel {
    func clearError() {
        DispatchQueue.main.async {
            self.error = nil
        }
    }
    
    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.isLoading = false
        }
    }
}

/// A base class that provides common view model functionality
class BaseViewModelImpl: BaseViewModel {
    @Published var isLoading = false
    @Published var error: Error?
    
    init() {}
}

/// A protocol for view models that manage forms
protocol BaseFormViewModel: BaseViewModel {
    /// Validates the form data
    func validate() -> Bool
    
    /// Resets the form to its initial state
    func clearForm()
    
    /// Saves the form data
    func save() async throws
    
    /// The validation errors for the form, if any
    var validationErrors: [String] { get }
}

/// Default implementation of BaseFormViewModel
extension BaseFormViewModel {
    var validationErrors: [String] {
        []
    }
    
    func clearForm() {
        clearError()
    }
} 