// Created by Lunar on 28/01/2022.
//

import Foundation
import Resolver
import CoreData

class ReorderingDashboardViewModel: ObservableObject {
    @Published var sessions: [Sessionable] = []
    @Published var isLoading = true
    @Published var currentlyDraggedSession: Sessionable?
    var thresholds: [SensorThreshold]
    private var context: NSManagedObjectContext

    @Injected private var uiStorage: UIStorage
    @Injected private var externalSessionsStore: ExternalSessionsStore
    @Injected private var measurementStreamStorage: MeasurementStreamStorage

    init(thresholds: [SensorThreshold], context: NSManagedObjectContext) {
        self.thresholds = thresholds
        self.context = context
        fetchSessions()
    }

    func clear(session: Sessionable) {
        sessions.removeAll(where: { $0.uuid == session.uuid })
        if session.isExternal {
            deleteExternalSession(with: session.uuid)
        } else {
            unfollowFixedSession(with: session.uuid)
        }
    }

    func finish() {
        uiStorage.accessStorage { storage in
            self.sessions.reversed().enumerated().forEach { index, session in
                storage.updateSessionOrder(index + 1, for: session.uuid)
            }
        }
    }

    private func deleteExternalSession(with uuid: SessionUUID) {
        externalSessionsStore.deleteSession(uuid: uuid) { result in
            switch result {
            case .success:
                Log.info("Deleted external session")
            case .failure(let error):
                Log.error("Failed to delete External Session: \(error)")
            }
        }
    }

    private func unfollowFixedSession(with uuid: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            storage.updateSessionFollowing(.notFollowing, for: uuid)
            self.uiStorage.accessStorage { uiStorage in
                uiStorage.setOrderToZero(for: uuid)
            }
        }
    }
    
    private func fetchSessions() {
        performFetch { self.sessions = $0; self.isLoading = false }
    }

    private func performFetch(completion: @escaping ([Sessionable]) -> Void) {
        context.perform {
            do {
                let externalRequest = NSFetchRequest<ExternalSessionEntity>(entityName: "ExternalSessionEntity")
                externalRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

                let request = NSFetchRequest<SessionEntity>(entityName: "SessionEntity")
                request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
                request.predicate = NSPredicate(format: "followedAt != NULL")

                let sessionEntities = try self.context.fetch(request)
                let externalSessionEntities = try self.context.fetch(externalRequest)
                let allSessions: [Sessionable] = (sessionEntities + externalSessionEntities).sorted {
                    ($0.userInterface?.rowOrder ?? 0) > ($1.userInterface?.rowOrder ?? 0)
                }
                completion(allSessions)
            } catch {
                Log.error("Failed to fetched sessions for reordering")
            }
        }
    }
}
