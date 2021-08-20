// Created by Lunar on 13/08/2021.
//

import Foundation

class StandardSesssionStopper: SessionStoppable {
    private let uuid: SessionUUID
    private let measurementStreamStorage: MeasurementStreamStorage
    
    init(uuid: SessionUUID, measurementStreamStorage: MeasurementStreamStorage) {
        self.uuid = uuid
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func stopSession() throws {
        Log.verbose("Stopping session with uuid \(uuid.rawValue) using standard session stopper")
        try measurementStreamStorage.updateSessionStatus(.FINISHED, for: uuid)
    }
}
