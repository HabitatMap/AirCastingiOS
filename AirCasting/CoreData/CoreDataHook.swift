// Created by Lunar on 17/05/2021.
//

import Foundation
import CoreData

final class CoreDataHook: NSObject, ObservableObject {
    @Published private(set) var sessions: [SessionEntity] = []
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    private lazy var fetchedResultsController: NSFetchedResultsController<SessionEntity> = {
        let request = NSFetchRequest<SessionEntity>(entityName: "SessionEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        let fetchedResultsController = NSFetchedResultsController<SessionEntity>(fetchRequest: request,
                                                                             managedObjectContext: context,
                                                                             sectionNameKeyPath: nil,
                                                                             cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    func setup(selectedSection: SelectedSection) throws {
        let predicate: NSPredicate
        switch selectedSection {
        case .fixed:
            predicate = NSPredicate(format: "type == %@", SessionType.fixed.rawValue)
        case .mobileActive:
            predicate = NSPredicate(format: "type == %@ AND (status == %li || status == %li || status == %li)", SessionType.mobile.rawValue,
                                    SessionStatus.RECORDING.rawValue,
                                    SessionStatus.DISCONNECTED.rawValue,
                                    SessionStatus.NEW.rawValue)
        case .mobileDormant:
            predicate = NSPredicate(format: "type == %@ AND status == %li", SessionType.mobile.rawValue, SessionStatus.FINISHED.rawValue)
        case .following:
            predicate = NSPredicate(format: "followedAt != NULL")
        }
        fetchedResultsController.fetchRequest.predicate = predicate
        try fetchedResultsController.performFetch()
        
        sessions = fetchedResultsController.fetchedObjects ?? []
    }
}

extension CoreDataHook: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sessions = fetchedResultsController.fetchedObjects ?? []
    }
}
