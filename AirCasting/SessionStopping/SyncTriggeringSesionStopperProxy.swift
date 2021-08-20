// Created by Lunar on 13/08/2021.
//

import Foundation

class SyncTriggeringSesionStopperProxy: SessionStoppable {
    private let stoppable: SessionStoppable
    private let synchronizer: SessionSynchronizer
    
    init(stoppable: SessionStoppable, synchronizer: SessionSynchronizer) {
        self.stoppable = stoppable
        self.synchronizer = synchronizer
    }
    
    func stopSession() throws {
        try stoppable.stopSession()
        synchronizer.triggerSynchronization()
    }
}
