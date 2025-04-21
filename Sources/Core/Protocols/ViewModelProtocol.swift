import Foundation
import Combine

/// Base protocol that all ViewModels should conform to
protocol ViewModelProtocol: ObservableObject {
    /// The type of state managed by this ViewModel
    associatedtype State
    
    /// The current state of the ViewModel
    var state: State { get }
    
    /// Publisher for state changes
    var statePublisher: Published<State>.Publisher { get }
    
    /// Initialize the ViewModel with the dependency container
    init(container: DependencyContainer)
}

/// Represents the loading state of async operations
enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

/// Base protocol for ViewModels that manage async loading operations
protocol AsyncLoadingViewModel: ViewModelProtocol {
    /// The current loading state
    var loadingState: LoadingState { get }
    
    /// Publisher for loading state changes
    var loadingStatePublisher: Published<LoadingState>.Publisher { get }
    
    /// Reload the ViewModel's data
    func reload() async throws
}

/// Base protocol for ViewModels that manage form input
protocol FormViewModel: ViewModelProtocol {
    /// Validate the current form state
    func validate() -> Bool
    
    /// Reset the form to its initial state
    func reset()
    
    /// Submit the form
    func submit() async throws
}

/// Base protocol for ViewModels that manage lists of items
protocol ListViewModel: AsyncLoadingViewModel {
    /// The type of items in the list
    associatedtype Item: Identifiable
    
    /// The current items in the list
    var items: [Item] { get }
    
    /// Publisher for items changes
    var itemsPublisher: Published<[Item]>.Publisher { get }
    
    /// Delete an item from the list
    func deleteItem(_ item: Item) async throws
    
    /// Move an item within the list
    func moveItem(from: IndexSet, to: Int) async throws
} 