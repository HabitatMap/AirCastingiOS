// Created by Lunar on 17/05/2021.
//

import Foundation
import CoreData

final class CoreDataHook: NSObject, ObservableObject {
    @Published private(set) var sessions: [Sessionable] = []
    
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
    
    private lazy var externalSessionsFetchedResultsController: NSFetchedResultsController<ExternalSessionEntity> = {
        let request = NSFetchRequest<ExternalSessionEntity>(entityName: "ExternalSessionEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        let fetchedResultsController = NSFetchedResultsController<ExternalSessionEntity>(fetchRequest: request,
                                                                             managedObjectContext: context,
                                                                             sectionNameKeyPath: nil,
                                                                             cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    func setup(selectedSection: SelectedSection) throws {
        let predicate: NSPredicate
        var externalSessionsPredicate = NSPredicate(value: false)
        
        switch selectedSection {
        case .fixed:
            predicate = NSPredicate(format: "type == %@", SessionType.fixed.rawValue)
            fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        case .mobileActive:
            predicate = NSPredicate(format: "type == %@ AND (status == %li || status == %li || status == %li)", SessionType.mobile.rawValue,
                                    SessionStatus.RECORDING.rawValue,
                                    SessionStatus.DISCONNECTED.rawValue,
                                    SessionStatus.NEW.rawValue)
            fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        case .mobileDormant:
            predicate = NSPredicate(format: "type == %@ AND status == %li", SessionType.mobile.rawValue, SessionStatus.FINISHED.rawValue)
            fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        case .following:
            predicate = NSPredicate(format: "followedAt != NULL")
            fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "rowOrder", ascending: false), NSSortDescriptor(key: "startTime", ascending: false)]
            externalSessionsPredicate = NSPredicate(value: true)
        }
        fetchedResultsController.fetchRequest.predicate = predicate
        externalSessionsFetchedResultsController.fetchRequest.predicate = externalSessionsPredicate
        try fetchedResultsController.performFetch()
        try externalSessionsFetchedResultsController.performFetch()
        
        refreshSessions()
    }
    
    func refreshSessions() {
        let sessionEntities = fetchedResultsController.fetchedObjects ?? []
        let externalSessionEntities = externalSessionsFetchedResultsController.fetchedObjects ?? []
        sessions = sessionEntities + externalSessionEntities
    }
}

extension CoreDataHook: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        refreshSessions()
    }
}
