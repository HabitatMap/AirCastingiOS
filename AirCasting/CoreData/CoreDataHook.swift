// Created by Lunar on 17/05/2021.
//

import Foundation
import CoreData

final class CoreDataHook: NSObject, ObservableObject {
    
    @Published var sessions: [Session] = []
    private var fetchedResultsController: NSFetchedResultsController<Session>?
    
    func setup(selectedSection: SelectedSection, context: NSManagedObjectContext) throws {
        
        let request = NSFetchRequest<Session>(entityName: "Session")
        
        switch selectedSection {
        case .fixed:
            request.predicate = NSPredicate(format: "type == %@", SessionType.fixed.rawValue)
        case .mobileActive:
            request.predicate = NSPredicate(format: "type == %@ AND status == %li", SessionType.mobile.rawValue, SessionStatus.RECORDING.rawValue)
        case .mobileDormant:
            request.predicate = NSPredicate(format: "type == %@ AND status == %li", SessionType.mobile.rawValue, SessionStatus.FINISHED.rawValue)
        case .following:
            request.predicate = NSPredicate(format: "followedAt != NULL")
        }
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController<Session>(fetchRequest: request,
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
