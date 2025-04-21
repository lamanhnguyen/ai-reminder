import SwiftUI

/// A view modifier that presents errors using alerts
struct ErrorPresentationModifier: ViewModifier {
    /// The error middleware instance to observe
    @ObservedObject var middleware: ErrorMiddleware
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: .init(
                    get: { middleware.isPresenting },
                    set: { if !$0 { middleware.clearError() } }
                )
            ) {
                Button("OK") {
                    middleware.clearError()
                }
            } message: {
                Text(middleware.currentErrorMessage())
            }
    }
}

extension View {
    /// Adds error presentation handling to a view
    /// - Parameter middleware: The error middleware instance to use
    /// - Returns: A view with error presentation handling
    func handleErrors(using middleware: ErrorMiddleware) -> some View {
        modifier(ErrorPresentationModifier(middleware: middleware))
    }
} 