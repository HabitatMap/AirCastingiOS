// Created by Lunar on 13/08/2021.
//

import Foundation
import Resolver

class StandardSesssionStopper: SessionStoppable {
    private let uuid: SessionUUID
    @Injected private var sessionStorage: SessionStorage
    @Injected private var bluetoothManager: BluetoothManager
    
    init(uuid: SessionUUID) {
        self.uuid = uuid
    }
    
    func stopSession() {
        Log.verbose("Stopping session with uuid \(uuid.rawValue) using standard session stopper")
        bluetoothManager.finishMobileSession(with: uuid)
        self.sessionStorage.accessStorage { storage in
            do {
                try storage.clearBluetoothPeripheralUUID(self.uuid)
            } catch {
                Log.error("Error occured while using storage \(error.localizedDescription)")
            }
        }
    }
}
