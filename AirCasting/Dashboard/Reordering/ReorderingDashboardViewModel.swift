// Created by Lunar on 28/01/2022.
//

import Foundation
import Resolver

class ReorderingDashboardViewModel: ObservableObject {
    @Published var sessions: [Sessionable]
    var thresholds: [SensorThreshold]
    
    @Published var currentlyDraggedSession: Sessionable?
    private let measurementStreamStorage: MeasurementStreamStorage
    
    init(sessions: [Sessionable], thresholds: [SensorThreshold]) {
        self.sessions = sessions
        self.measurementStreamStorage = Resolver.resolve()
        self.thresholds = thresholds
    }
    
    func finish() {
        measurementStreamStorage.accessStorage { storage in
            self.sessions.reversed().enumerated().forEach { index, session in
                // TODO: implement new logic for saving new sessions order
                storage.updateSessionOrder(index + 1, for: session.uuid)
            }
        }
    }
}
