// Created by Lunar on 13/08/2021.
//

import Foundation
import Combine

class SyncTriggeringSesionStopperDecorator: SessionStoppable {
    private let stoppable: SessionStoppable
    private let synchronizer: SessionSynchronizer
    private var syncCancellable: AnyCancellable?
    
    init(stoppable: SessionStoppable, synchronizer: SessionSynchronizer) {
        self.stoppable = stoppable
        self.synchronizer = synchronizer
    }
    
    func stopSession() throws {
        try stoppable.stopSession()
        if synchronizer.syncInProgress.value {
            syncCancellable = synchronizer.syncInProgress
                .receive(on: DispatchQueue.main)
                .sink { [weak self] inProgress in
                    guard !inProgress, let self = self else { return }
                    self.syncCancellable?.cancel()
                    self.syncCancellable = nil
                    self.synchronizer.triggerSynchronization()
                }
        } else {
            synchronizer.triggerSynchronization()
        }
    }
}
