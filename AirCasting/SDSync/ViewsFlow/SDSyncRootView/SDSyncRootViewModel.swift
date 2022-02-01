// Created by Lunar on 02/12/2021.
//

import Foundation
import Combine
import Resolver

class SDSyncRootViewModel: ObservableObject {
    
    @Published var backendSyncCompleted: Bool = false
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var urlProvider: URLProvider
    
    init() {
        self.sessionSynchronizer = sessionSynchronizer
        self.urlProvider = urlProvider
    }
    
    func executeBackendSync() {
        guard !sessionSynchronizer.syncInProgress.value else {
            onCurrentSyncEnd { self.startBackendSync() }
            return
        }
        startBackendSync()
    }
    
    private func startBackendSync() {
        sessionSynchronizer.triggerSynchronization() {
            DispatchQueue.main.async {
                self.backendSyncCompleted = true
            }
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
