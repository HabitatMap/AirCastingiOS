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
    
    init(thresholds: [SensorThreshold], context: NSManagedObjectContext) {
        self.thresholds = thresholds
        self.context = context
        fetchSessions()
    }
    
    func finish() {
        uiStorage.accessStorage { storage in
            self.sessions.reversed().enumerated().forEach { index, session in
                // TODO: implement new logic for saving new sessions order
                storage.updateSessionOrder(index + 1, for: session.uuid)
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
