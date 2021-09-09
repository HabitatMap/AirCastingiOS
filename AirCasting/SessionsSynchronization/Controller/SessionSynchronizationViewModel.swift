// Created by Lunar on 09/09/2021.
//

import Foundation

protocol DefaultSessionSynchronizer {
    var syncInProgress: Bool { get }
}

class SessionSynchronizationViewModel: DefaultSessionSynchronizer, ObservableObject {
    @Published var syncInProgress: Bool = false
    
    func toggleSyncState() {
        if syncInProgress { return }
        DispatchQueue.main.async {
            self.syncInProgress = true
        }
    }
    
    func finishSync() {
        DispatchQueue.main.async {
            self.syncInProgress = false
        }
    }
}
