// Created by Lunar on 13/08/2021.
//

import Foundation
import Resolver

class SyncTriggeringSesionStopperDecorator: SessionStoppable {
    private let stoppable: SessionStoppable
    private let synchronizer: SessionSynchronizer
    
    @InjectedObject private var userSettings: UserSettings
    @Injected private var networkChecker: NetworkChecker
    
    init(stoppable: SessionStoppable, synchronizer: SessionSynchronizer) {
        self.stoppable = stoppable
        self.synchronizer = synchronizer
    }
    
    func stopSession() throws {
        try stoppable.stopSession()
        
        guard !userSettings.syncOnlyThroughWifi || networkChecker.isUsingWifi else {
            Log.info("Skipping sync after finishing session because of no wifi connection")
            return
        }
        synchronizer.triggerSynchronization()
    }
}
