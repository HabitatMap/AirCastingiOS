// Created by Lunar on 09/09/2021.
//

import Foundation

protocol SessionSynchronizationViewModel {
    var syncInProgress: Bool { get }
    func toggleSyncState()
    func finishSync()
}

class DefaultSessionSynchronizationViewModel: SessionSynchronizationViewModel, ObservableObject {
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
