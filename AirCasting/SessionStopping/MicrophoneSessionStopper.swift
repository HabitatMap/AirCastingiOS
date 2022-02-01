// Created by Lunar on 13/08/2021.
//

import Foundation
import Resolver

class MicrophoneSessionStopper: SessionStoppable {
    private let uuid: SessionUUID
    @Injected private var microphoneManager: MicrophoneManager
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    
    init(uuid: SessionUUID) {
        self.uuid = uuid
    }
    
    func stopSession() throws {
        Log.verbose("Stopping session with uuid \(uuid.rawValue) using microphone session stopper")
        microphoneManager.stopRecording()
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.updateSessionEndtime(DateBuilder.getRawDate(), for: self.uuid)
                try storage.updateSessionStatus(.FINISHED, for: self.uuid)
            } catch {
                Log.info("\(error)")
            }
        }
    }
}
