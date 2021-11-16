// Created by Lunar on 16/11/2021.
//

import Foundation
import Combine

class SDSyncViewModel {
    private let sessionSynchronizer: SessionSynchronizer
    
    init(sessionSynchronizer: SessionSynchronizer) {
        self.sessionSynchronizer = sessionSynchronizer
    }
    
    func startSync() {
        Log.info("## Started sync")
        syncWithBackend()
    }
    
    func syncWithBackend() {
        Log.info("## Going to sync with backend")
        guard !sessionSynchronizer.syncInProgress.value else {
            onCurrentSyncEnd { self.startBackendSync() }
            return
        }
        
        startBackendSync()
    }
    
    func startBackendSync() {
        sessionSynchronizer.triggerSynchronization() { Log.info("## Sync completed") }
    }
    
    private func onCurrentSyncEnd(_ completion: @escaping () -> Void) {
            guard sessionSynchronizer.syncInProgress.value else { completion(); return }
            var cancellable: AnyCancellable?
            cancellable = sessionSynchronizer.syncInProgress.sink { syncInProgress in
                guard !syncInProgress else { return }
                completion()
                cancellable?.cancel()
            }
        }
}
