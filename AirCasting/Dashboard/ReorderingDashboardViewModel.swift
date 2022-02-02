// Created by Lunar on 28/01/2022.
//

import Foundation

class ReorderingDashboardViewModel: ObservableObject {
    @Published var sessions: [SessionEntity]
    
    @Published var currentSession: SessionEntity?
    private let measurementStreamStorage: MeasurementStreamStorage
    
    init(sessions: [SessionEntity], measurementStreamStorage: MeasurementStreamStorage) {
        self.sessions = sessions
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func finish() {
        measurementStreamStorage.accessStorage { storage in
            self.sessions.reversed().enumerated().forEach { index, session in
                storage.updateSessionOrder(index + 1, for: session.uuid)
            }
        }
    }
}
