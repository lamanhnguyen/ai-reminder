import Foundation
import Combine
import OSLog

/// Protocol defining the requirements for error handling middleware
protocol ErrorHandling {
    /// Handle an error and return a user-friendly message
    /// - Parameter error: The error to handle
    /// - Returns: A user-friendly error message
    func handle(_ error: Error) -> String
    
    /// Check if an error can be handled by this middleware
    /// - Parameter error: The error to check
    /// - Returns: Whether this middleware can handle the error
    func canHandle(_ error: Error) -> Bool
}

/// Protocol for error presentation
protocol ErrorPresenting {
    /// Present an error to the user
    /// - Parameter message: The error message to present
    func presentError(_ message: String)
}

/// Middleware for handling and presenting errors throughout the app
final class ErrorMiddleware: ObservableObject {
    // MARK: - Published Properties
    
    /// The current error being presented to the user
    @Published private(set) var currentError: Error?
    
    /// Whether an error is currently being presented
    @Published private(set) var isPresenting: Bool = false
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VoiceReminders", category: "ErrorMiddleware")
    
    /// Array of error handlers
    private var handlers: [ErrorHandling] = []
    
    /// Error presenter
    private weak var presenter: ErrorPresenting?
    
    // MARK: - Initialization
    
    private init() {
        setupDefaultHandlers()
    }
    
    // MARK: - Setup
    
    private func setupDefaultHandlers() {
        // Add handlers for common error types
        handlers.append(NetworkErrorHandler())
        handlers.append(ValidationErrorHandler())
        handlers.append(ServiceErrorHandler())
        handlers.append(PersistenceErrorHandler())
        handlers.append(GeneralErrorHandler())
    }
    
    // MARK: - Configuration
    
    /// Set the error presenter
    /// - Parameter presenter: The object responsible for presenting errors
    func setPresenter(_ presenter: ErrorPresenting) {
        self.presenter = presenter
    }
    
    /// Add a custom error handler
    /// - Parameter handler: The error handler to add
    func addHandler(_ handler: ErrorHandling) {
        handlers.insert(handler, at: 0)
    }
    
    // MARK: - Public Methods
    
    /// Handle a new error by logging it and preparing it for presentation
    /// - Parameter error: The error to handle
    func handle(_ error: Error) {
        // Log the error
        logger.error("Error occurred: \(error.localizedDescription)")
        
        // Set the current error and mark it for presentation
        currentError = error
        isPresenting = true
    }
    
    /// Clear the current error and reset the presentation state
    func clearError() {
        currentError = nil
        isPresenting = false
    }
    
    /// Get a user-friendly error message for the current error
    /// - Returns: A localized error message suitable for display to the user
    func currentErrorMessage() -> String {
        guard let error = currentError else {
            return NSLocalizedString("An unknown error occurred", comment: "Unknown error message")
        }
        
        // Use the error's localized description or a custom message based on error type
        switch error {
        case let networkError as NetworkError:
            return networkError.localizedDescription
        case let validationError as ValidationError:
            return validationError.localizedDescription
        case let serviceError as ServiceError:
            return serviceError.localizedDescription
        case let persistenceError as PersistenceError:
            return persistenceError.localizedDescription
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Default Error Handlers

/// Handler for network-related errors
private struct NetworkErrorHandler: ErrorHandling {
    func canHandle(_ error: Error) -> Bool {
        error is NetworkError
    }
    
    func handle(_ error: Error) -> String {
        guard let networkError = error as? NetworkError else {
            return "An unexpected network error occurred"
        }
        
        switch networkError {
        case .noInternet:
            return "No internet connection. Please check your network settings and try again."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .invalidResponse:
            return "Invalid response received from the server. Please try again."
        case .unauthorized:
            return "You are not authorized to perform this action. Please log in and try again."
        }
    }
}

/// Handler for validation-related errors
private struct ValidationErrorHandler: ErrorHandling {
    func canHandle(_ error: Error) -> Bool {
        error is ValidationError
    }
    
    func handle(_ error: Error) -> String {
        guard let validationError = error as? ValidationError else {
            return "A validation error occurred"
        }
        
        switch validationError {
        case .invalidField(let field, let message):
            return "\(field) is invalid: \(message)"
        case .requiredField(let field):
            return "\(field) is required"
        case .invalidFormat(let message):
            return "Invalid format: \(message)"
        }
    }
}

/// Handler for service-related errors
private struct ServiceErrorHandler: ErrorHandling {
    func canHandle(_ error: Error) -> Bool {
        error is ServiceError
    }
    
    func handle(_ error: Error) -> String {
        guard let serviceError = error as? ServiceError else {
            return "A service error occurred"
        }
        
        switch serviceError {
        case .notFound(let item):
            return "\(item) not found"
        case .alreadyExists(let item):
            return "\(item) already exists"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .unknown(let underlyingError):
            return "An unexpected error occurred: \(underlyingError.localizedDescription)"
        }
    }
}

/// Handler for persistence-related errors
private struct PersistenceErrorHandler: ErrorHandling {
    func canHandle(_ error: Error) -> Bool {
        error is PersistenceError
    }
    
    func handle(_ error: Error) -> String {
        guard let persistenceError = error as? PersistenceError else {
            return "A data persistence error occurred"
        }
        
        switch persistenceError {
        case .saveFailed(let message):
            return "Failed to save data: \(message)"
        case .loadFailed(let message):
            return "Failed to load data: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete data: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}

/// Handler for general errors
private struct GeneralErrorHandler: ErrorHandling {
    func canHandle(_ error: Error) -> Bool {
        true // Handles any error as a fallback
    }
    
    func handle(_ error: Error) -> String {
        "An unexpected error occurred. Please try again later."
    }
} 