import Foundation
import SwiftUI
import Combine

/// Represents the state of a ViewModel's operation
public enum ViewModelState: Equatable {
    case idle
    case loading
    case error(String)
    case success
}

/// Represents the state of an asynchronous operation
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}

/// Protocol defining the basic requirements for all ViewModels
public protocol BaseViewModel: ObservableObject {
    /// The current state of the ViewModel
    var state: ViewModelState { get set }
    
    /// Any error messages that need to be displayed
    var errorMessage: String? { get set }
    
    /// Subscription storage to prevent premature cancellation
    var subscriptions: Set<AnyCancellable> { get set }
    
    /// Initialize the ViewModel and set up any necessary subscriptions
    func initialize()
    
    /// Clean up any resources when the ViewModel is no longer needed
    func cleanup()
    
    /// Handle errors in a consistent way
    func handleError(_ error: Error)
}

/// Protocol defining common functionality for all view models
@MainActor
protocol BaseViewModel: ObservableObject {
    /// The current loading state of the view model
    var loadingState: LoadingState { get }
    
    /// Whether the view model is currently loading data
    var isLoading: Bool { get }
    
    /// The current error message, if any
    var errorMessage: String? { get }
    
    /// Reset the view model to its initial state
    func reset()
    
    /// Handle an error that occurred during an operation
    func handleError(_ error: Error)
}

/// Default implementation of BaseViewModel
public extension BaseViewModel {
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        state = .error(error.localizedDescription)
    }
    
    func cleanup() {
        subscriptions.removeAll()
    }
}

/// Protocol for ViewModels that manage forms
public protocol FormViewModel: BaseViewModel {
    /// Whether the form is currently valid
    var isValid: Bool { get set }
    
    /// Dictionary of field validation errors
    var fieldErrors: [String: String] { get set }
    
    /// Validate all form fields
    func validateForm() -> Bool
    
    /// Submit the form
    func submitForm() async throws
}

/// Protocol for ViewModels that manage lists
public protocol ListViewModel: BaseViewModel {
    /// The type of items in the list
    associatedtype Item: Identifiable
    
    /// The items in the list
    var items: [Item] { get set }
    
    /// Load items for the list
    func loadItems() async throws
    
    /// Refresh the list
    func refresh() async throws
    
    /// Delete an item
    func deleteItem(_ item: Item) async throws
}

/// Protocol for ViewModels that support searching
public protocol SearchableViewModel: BaseViewModel {
    /// The current search query
    var searchQuery: String { get set }
    
    /// Whether a search is currently in progress
    var isSearching: Bool { get set }
    
    /// Perform a search with the current query
    func performSearch() async throws
}

/// Protocol for ViewModels that manage detail views
public protocol DetailViewModel: BaseViewModel {
    /// The type of the item being displayed
    associatedtype Item
    
    /// The item being displayed
    var item: Item { get set }
    
    /// Load the item details
    func loadDetails() async throws
    
    /// Save changes to the item
    func saveChanges() async throws
}

/// Defines the base requirements for all ViewModels in the app
protocol ViewModel: ObservableObject {
    /// The type of state managed by this ViewModel
    associatedtype State
    
    /// The current state of the ViewModel
    var state: State { get }
    
    /// Handles errors that occur within the ViewModel
    func handleError(_ error: Error)
}

/// Represents a ViewModel that can be initialized with dependencies
protocol InitializableViewModel: ViewModel {
    /// The type of dependencies required by this ViewModel
    associatedtype Dependencies
    
    /// Initialize the ViewModel with its required dependencies
    init(dependencies: Dependencies)
}

/// Represents a ViewModel that manages loading states
protocol LoadableViewModel: ViewModel {
    /// Indicates if the ViewModel is currently loading data
    var isLoading: Bool { get }
    
    /// Indicates if there was an error during the last load operation
    var loadingError: Error? { get }
    
    /// Reload the ViewModel's data
    func reload() async
}

/// Represents a ViewModel that can be refreshed
protocol RefreshableViewModel: ViewModel {
    /// Refresh the ViewModel's data
    func refresh() async
    
    /// Indicates if the ViewModel is currently refreshing
    var isRefreshing: Bool { get }
}

/// Base class for all view models in the app
class BaseViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Service container instance
    let container: ServiceContainer
    
    /// Set of cancellables for managing subscriptions
    var cancellables = Set<AnyCancellable>()
    
    /// Published property to track loading state
    @Published private(set) var isLoading = false
    
    /// Published property to track the current error
    @Published private(set) var error: Error?
    
    // MARK: - Service Access
    
    /// Core Data service for persistence operations
    var coreDataService: CoreDataServiceProtocol {
        guard let service = container.coreDataService else {
            fatalError("CoreDataService not registered")
        }
        return service
    }
    
    /// Service for managing reminders
    var remindersService: RemindersServiceProtocol {
        guard let service = container.remindersService else {
            fatalError("RemindersService not registered")
        }
        return service
    }
    
    /// Service for voice recognition
    var voiceRecognitionService: VoiceRecognitionServiceProtocol {
        guard let service = container.voiceRecognitionService else {
            fatalError("VoiceRecognitionService not registered")
        }
        return service
    }
    
    /// Service for managing notifications
    var notificationService: NotificationServiceProtocol {
        guard let service = container.notificationService else {
            fatalError("NotificationService not registered")
        }
        return service
    }
    
    // MARK: - Initialization
    
    /// Initialize with a service container
    /// - Parameter container: The service container to use. Defaults to the shared instance.
    init(container: ServiceContainer = .shared) {
        self.container = container
        setupSubscriptions()
    }
    
    // MARK: - Setup
    
    /// Set up any subscriptions needed by the view model
    /// Override this method in subclasses to add custom subscriptions
    func setupSubscriptions() {
        // Base implementation does nothing
        // Subclasses should override this to set up their own subscriptions
    }
    
    // MARK: - Cleanup
    
    /// Clean up any resources used by the view model
    /// This is called automatically when the view model is deinitialized
    func cleanup() {
        cancellables.removeAll()
    }
    
    deinit {
        cleanup()
    }
    
    /// Handle errors by publishing them to the error property
    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    /// Set loading state with optional completion handler
    func setLoading(_ loading: Bool, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.isLoading = loading
            completion?()
        }
    }
    
    /// Clear any current error
    func clearError() {
        DispatchQueue.main.async {
            self.error = nil
        }
    }
    
    /// Perform an async operation with automatic loading state management
    func performAsync<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        setLoading(true)
        do {
            let result = try await operation()
            setLoading(false)
            return result
        } catch {
            setLoading(false)
            handleError(error)
            throw error
        }
    }
}

/// Base class for ViewModels that provides common functionality
class BaseViewModel<State>: ViewModelProtocol {
    /// The dependency container
    let container: DependencyContainer
    
    /// The current state of the ViewModel
    @Published private(set) var state: State
    
    /// Publisher for state changes
    var statePublisher: Published<State>.Publisher { $state }
    
    /// Set of cancellables for managing subscriptions
    var cancellables = Set<AnyCancellable>()
    
    /// Initialize the ViewModel with the dependency container and initial state
    required init(container: DependencyContainer, initialState: State) {
        self.container = container
        self.state = initialState
    }
    
    /// Required initializer from ViewModelProtocol
    /// - Note: This should not be called directly. Use init(container:initialState:) instead
    required init(container: DependencyContainer) {
        fatalError("init(container:) has not been implemented. Use init(container:initialState:) instead")
    }
    
    /// Update the state using a closure
    /// - Parameter updateBlock: A closure that takes the current state and returns the new state
    func updateState(_ updateBlock: (inout State) -> Void) {
        var newState = state
        updateBlock(&newState)
        state = newState
    }
    
    /// Handle errors in a consistent way
    /// - Parameter error: The error to handle
    /// - Returns: A user-friendly error message
    func handleError(_ error: Error) -> String {
        // Log the error
        print("Error in \(type(of: self)): \(error)")
        
        // Convert to user-friendly message
        switch error {
        case let networkError as NetworkError:
            return networkError.userMessage
        case let validationError as ValidationError:
            return validationError.message
        default:
            return "An unexpected error occurred. Please try again."
        }
    }
}

/// Base class for ViewModels that manage async loading operations
class BaseAsyncViewModel<State>: BaseViewModel<State>, AsyncLoadingViewModel {
    /// The current loading state
    @Published private(set) var loadingState: LoadingState = .idle
    
    /// Publisher for loading state changes
    var loadingStatePublisher: Published<LoadingState>.Publisher { $loadingState }
    
    /// Perform an async operation with loading state management
    /// - Parameter operation: The async operation to perform
    func performAsync<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        loadingState = .loading
        
        do {
            let result = try await operation()
            loadingState = .loaded
            return result
        } catch {
            let errorMessage = handleError(error)
            loadingState = .error(errorMessage)
            throw error
        }
    }
    
    /// Reload the ViewModel's data
    /// - Note: This should be implemented by subclasses
    func reload() async throws {
        fatalError("reload() has not been implemented")
    }
}

/// Common errors that can occur in ViewModels
enum NetworkError: Error {
    case noInternet
    case serverError
    case unauthorized
    case notFound
    
    var userMessage: String {
        switch self {
        case .noInternet:
            return "Please check your internet connection and try again."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .notFound:
            return "The requested resource could not be found."
        }
    }
}

/// Validation errors that can occur in forms
struct ValidationError: Error {
    let message: String
}

/// Base class providing common view model functionality
@MainActor
class BaseViewModelImpl: BaseViewModel {
    @Published private(set) var loadingState: LoadingState = .idle
    private var cancellables = Set<AnyCancellable>()
    
    func reset() {
        loadingState = .idle
        cancellables.removeAll()
    }
    
    /// Execute an async operation with loading state management
    /// - Parameter operation: The async operation to execute
    /// - Returns: The result of the operation
    func withLoading<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        loadingState = .loading
        do {
            let result = try await operation()
            loadingState = .loaded
            return result
        } catch {
            handleError(error)
            throw error
        }
    }
    
    /// Subscribe to a publisher and update loading state
    /// - Parameters:
    ///   - publisher: The publisher to subscribe to
    ///   - completion: Closure to handle the received value
    func subscribe<T>(_ publisher: AnyPublisher<T, Error>,
                     completion: @escaping (T) -> Void) {
        loadingState = .loading
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.loadingState = .loaded
                case .failure(let error):
                    self?.handleError(error)
                }
            } receiveValue: { value in
                completion(value)
            }
            .store(in: &cancellables)
    }
} 