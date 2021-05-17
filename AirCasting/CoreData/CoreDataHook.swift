// Created by Lunar on 17/05/2021.
//

import Foundation
import CoreData

class CoreDataHook: NSObject, ObservableObject {
    
    @Published var sessions: [Session] = []
    var context: NSManagedObjectContext!
    
    var fetchRequest: NSFetchRequest<Session>! {
        didSet {
            do {
                try setup()
            } catch {
                Log.error("Trying to fetch sessions. Error: \(error)")
            }
        }
    }
    
    private var fetchedResultsController: NSFetchedResultsController<Session>!
    
    func setup() throws {
        fetchedResultsController = NSFetchedResultsController<Session>(fetchRequest: fetchRequest,
                                                                       managedObjectContext: context,
                                                                       sectionNameKeyPath: nil,
                                                                       cacheName: nil)
        try fetchedResultsController.performFetch()
        fetchedResultsController.delegate = self
        sessions = fetchedResultsController.fetchedObjects ?? []
    }
}

extension CoreDataHook: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sessions = fetchedResultsController.fetchedObjects ?? []
    }
}
