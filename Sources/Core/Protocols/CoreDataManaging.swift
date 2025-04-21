import Foundation
import CoreData

protocol CoreDataManaging {
    var viewContext: NSManagedObjectContext { get }
    var backgroundContext: NSManagedObjectContext { get }
    
    func saveContext() throws
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) throws -> Void) async throws
} 