// Created by Lunar on 17/05/2021.
//

import Foundation
import CoreData

final class CoreDataHook: NSObject, ObservableObject {
    
    @Published var sessions: [Session] = []
    private var fetchedResultsController: NSFetchedResultsController<Session>?
    
    func setup(fetchRequest: NSFetchRequest<Session>, context: NSManagedObjectContext) throws {
        
        
        
        
        fetchedResultsController = NSFetchedResultsController<Session>(fetchRequest: fetchRequest,
                                                                       managedObjectContext: context,
                                                                       sectionNameKeyPath: nil,
                                                                       cacheName: nil)
        guard let fetchedResultsController = fetchedResultsController else {
            throw FetchError.fetchedResultsControllerIsNil
        }
        try fetchedResultsController.performFetch()
        fetchedResultsController.delegate = self
        sessions = fetchedResultsController.fetchedObjects ?? []
    }
}

extension CoreDataHook: NSFetchedResultsControllerDelegate {
    
    private func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) throws {
        guard let fetchedResultsController = fetchedResultsController else {
            throw FetchError.fetchedResultsControllerIsNil
        }
        sessions = fetchedResultsController.fetchedObjects ?? []
    }
}

enum FetchError: Error {
    case fetchedResultsControllerIsNil
}
