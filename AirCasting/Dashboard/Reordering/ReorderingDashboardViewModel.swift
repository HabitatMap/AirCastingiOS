// Created by Lunar on 28/01/2022.
//

import Foundation
import Resolver

class ReorderingDashboardViewModel: ObservableObject {
    @Published var sessions: [Sessionable]
    var thresholds: [SensorThreshold]
    
    @Published var currentlyDraggedSession: Sessionable?
    @Injected private var uiStorage: UIStorage
    @Injected private var externalSessionsStore: ExternalSessionsStore
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    
    init(sessions: [Sessionable], thresholds: [SensorThreshold]) {
        self.sessions = sessions
        self.thresholds = thresholds
    }
    
    func clear(session: Sessionable) {
        if session.isExternal {
            externalSessionsStore.deleteSession(uuid: session.uuid) { result in
                switch result {
                case .success:
                    Log.info("Deleted external session")
                case .failure(let error):
                    Log.error("Failed to delete External Session: \(error)")
                }
            }
        } else {
            measurementStreamStorage.accessStorage { storage in
                storage.updateSessionFollowing(.notFollowing, for: session.uuid)
                self.uiStorage.accessStorage { uiStorage in
                    uiStorage.setOrderToZero(for: session.uuid)
                }
            }
        }
    }
    
    func finish() {
        uiStorage.accessStorage { storage in
            self.sessions.reversed().enumerated().forEach { index, session in
                storage.updateSessionOrder(index + 1, for: session.uuid)
            }
        }
    }
}
