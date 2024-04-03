// Created by Lunar on 13/08/2021.
//

import Foundation
import Resolver

class StandardSesssionStopper: SessionStoppable {
    private let uuid: SessionUUID
    @Injected private var sessionStorage: SessionStorage
    @Injected private var sessionRecorder: BluetoothSessionRecordingController
    
    init(uuid: SessionUUID) {
        self.uuid = uuid
    }
    
    func stopSession() {
        Log.verbose("Stopping session with uuid \(self.uuid.rawValue) using standard session stopper")
        sessionRecorder.stopRecordingSession(with: uuid) {
            $0.accessStorage {
                do {
                    try $0.updateSessionStatus(.FINISHED, for: self.uuid)
                    try $0.updateSessionEndtime(DateBuilder.getRawDate(), for: self.uuid)
                } catch {
                    Log.error("Failed to make changes in database when stopping session")
                }
            }
        }
        self.sessionStorage.accessStorage { storage in
            do {
                try storage.clearBluetoothPeripheralUUID(self.uuid)
            } catch {
                Log.error("Error occured while using storage \(error.localizedDescription)")
            }
        }
    }
}
