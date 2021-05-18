// Created by Lunar on 17/05/2021.
//

import Foundation
import CoreData

final class CoreDataHook: NSObject, ObservableObject {
    
    @Published var sessions: [Session] = []
    var context: NSManagedObjectContext!
    private var fetchedResultsController: NSFetchedResultsController<Session>!
    
    func setup(selectedSection: SelectedSection) throws {
        
        let predicate: NSPredicate
        
        switch selectedSection {
        case .fixed:
            predicate = NSPredicate(format: "type == %@", SessionType.fixed.rawValue)
        case .mobileActive:
            predicate = NSPredicate(format: "type == %@ AND status == %li", SessionType.mobile.rawValue, SessionStatus.RECORDING.rawValue)
        case .mobileDormant:
            predicate = NSPredicate(format: "type == %@ AND status == %li", SessionType.mobile.rawValue, SessionStatus.FINISHED.rawValue)
        case .following:
            predicate = NSPredicate(format: "followedAt != NULL")
        }
        
        if fetchedResultsController == nil {
            let request = NSFetchRequest<Session>(entityName: "Session")
            request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
            request.predicate = predicate
            fetchedResultsController = NSFetchedResultsController<Session>(fetchRequest: request,
                                                                           managedObjectContext: context,
                                                                           sectionNameKeyPath: nil,
                                                                           cacheName: nil)
            fetchedResultsController.delegate = self
        }
        
        fetchedResultsController.fetchRequest.predicate = predicate
        try fetchedResultsController.performFetch()
        
        sessions = fetchedResultsController.fetchedObjects ?? []
    }
}

extension CoreDataHook: NSFetchedResultsControllerDelegate {
    
    internal func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sessions = fetchedResultsController.fetchedObjects ?? []
    }
}

enum FetchError: Error {
    case fetchedResultsControllerIsNil
}
