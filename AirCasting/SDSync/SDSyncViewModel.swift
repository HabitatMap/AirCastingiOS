// Created by Lunar on 16/11/2021.
//

import Foundation
import Combine

class SDSyncViewModel: ObservableObject {
    private let sessionSynchronizer: SessionSynchronizer
    private let sdSyncController: SDSyncController
    @Published var backendSyncCompleted = false
    
    init(sessionSynchronizer: SessionSynchronizer, sdSyncController: SDSyncController) {
        self.sessionSynchronizer = sessionSynchronizer
        self.sdSyncController = sdSyncController
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
        sessionSynchronizer.triggerSynchronization() {
            Log.info("## ended sync with backed")
            self.backendSyncCompleted = true
        }
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
