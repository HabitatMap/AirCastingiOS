// Created by Lunar on 18/11/2022.
//

import Foundation
import Resolver

protocol MobileSessionStorage {
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID)
    func updateSessionEndtime(_ endTime: Date, for uuid: SessionUUID)
}

class DefaultMobileSessionStorageBridge: MobileSessionStorage {
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(sessionStatus, for: sessionUUID)
            } catch {
                Log.error("Unable to change session status to disconnected because of an error: \(error)")
            }
        }
    }
    
    func updateSessionEndtime(_ endTime: Date, for uuid: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.FINISHED, for: uuid)
                try storage.updateSessionEndtime(DateBuilder.getRawDate(), for: uuid)
            } catch {
                Log.error("Unable to change session status to finished because of an error: \(error)")
            }
        }
    }
}
