// Created by Lunar on 17/05/2021.
//

import Foundation
import CoreData

final class CoreDataHook: NSObject, ObservableObject {
    @Published private(set) var sessions: [Sessionable] = []
    private var selectedSection: DashboardSection?
    private var observerToken: AnyObject?

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        observerToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: context, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            // The code below was preventing the UI from refreshing when new (first) measurement was inserted into a stream in a fixed session
            // Commenting it out seems to be logical (as the notification is sent only when something actually changes) and seems to solve the issue
            // But, as I am not fully confident in this change, I'm leaving the code commented out for now. It woud be good to understand why it was written in the first place.
//            let updatedIds = (notification.userInfo?["refreshed"] as? Set<NSManagedObject> ?? []).map(\.objectID)
//            let updatedIds = updateRefreshedIds + updateInsertedIds
//            
//            let changedInterfaces = self.sessions.compactMap(\.userInterface).filter {
//                updatedIds.contains($0.objectID)
//            }
//            
//            guard changedInterfaces.count > 0 else {
//                return
//            }
            Log.verbose("User interface changed!")
            self.refreshSessions()
        }
    }
    
    func setup(selectedSection: DashboardSection) throws {
        self.selectedSection = selectedSection
        try? performFetch(for: selectedSection)
        refreshSessions()
    }
    
    func getSessionsFor(section: DashboardSection) -> [Sessionable] {
        try? performFetch(for: section)
        let sessionEntities = fetchedResultsController.fetchedObjects ?? []
        let externalSessionEntities = externalSessionsFetchedResultsController.fetchedObjects ?? []
        return sessionEntities + externalSessionEntities
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
    
    private func refreshSessions() {
        Log.info("MARTA: refresh sessions")
        let sessionEntities = fetchedResultsController.fetchedObjects ?? []
        let externalSessionEntities = externalSessionsFetchedResultsController.fetchedObjects ?? []
        sessions = sessionEntities + externalSessionEntities
        Log.info("MARTA: following?: \(self.selectedSection)")
        guard case .following = selectedSection else { return }
        sessions = sessions.sorted {
            ($0.userInterface?.rowOrder ?? 0) > ($1.userInterface?.rowOrder ?? 0)
        }
//        Log.info("MARTA: Sessions in hook: \(self.sessions)")
//        Log.info("MARTA: Sessions measurements in hook: \(self.sessions.first?.sortedStreams.first?.measurements)")
    }
    
    private func performFetch(for selectedSection: DashboardSection) throws {
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
            fetchedResultsController.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
            externalSessionsPredicate = NSPredicate(value: true)
        }
        fetchedResultsController.fetchRequest.predicate = predicate
        externalSessionsFetchedResultsController.fetchRequest.predicate = externalSessionsPredicate
        try fetchedResultsController.performFetch()
        try externalSessionsFetchedResultsController.performFetch()
    }
}

extension CoreDataHook: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        refreshSessions()
    }
}
