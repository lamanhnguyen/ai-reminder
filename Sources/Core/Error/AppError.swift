import Foundation

/// Network-related errors
enum NetworkError: Error {
    case noInternet
    case serverError
    case invalidResponse
    case unauthorized
}

/// Validation-related errors
enum ValidationError: Error {
    case invalidField(String, String)
    case requiredField(String)
    case invalidFormat(String)
}

/// Service-related errors
enum ServiceError: Error {
    case notFound(String)
    case alreadyExists(String)
    case operationFailed(String)
    case unauthorized
    case unknown(Error)
}

/// Data persistence errors
enum PersistenceError: Error {
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case invalidData(String)
}

extension Error {
    /// Get a user-friendly description of the error
    var userFriendlyDescription: String {
        ErrorMiddleware.shared.handle(self)
    }
} 