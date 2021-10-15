// Created by Lunar on 13/08/2021.
//

import Foundation

class MicrophoneSessionStopper: SessionStoppable {
    private let uuid: SessionUUID
    private let microphoneManager: MicrophoneManager
    private let measurementStreamStorage: MeasurementStreamStorage
    
    init(uuid: SessionUUID, microphoneManager: MicrophoneManager, measurementStreamStorage: MeasurementStreamStorage) {
        self.uuid = uuid
        self.microphoneManager = microphoneManager
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func stopSession() throws {
        Log.verbose("Stopping session with uuid \(uuid.rawValue) using microphone session stopper")
        try microphoneManager.stopRecording()
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.updateSessionEndtime(Date(), for: self.uuid)
                try storage.updateSessionStatus(.FINISHED, for: self.uuid)
            } catch {
                Log.info("\(error)")
            }
        }
    }
}
