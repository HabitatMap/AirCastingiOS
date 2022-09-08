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
}
