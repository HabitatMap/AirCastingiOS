// Created by Lunar on 16/06/2021.
//

import Foundation
import Combine

/// Defines the interface for objects that provide session list synchronization to the app
protocol SessionSynchronizer {
    /// Triggers a new synchronization pass
    /// - Parameter completion: closure called when sycnhronization finishes
    func triggerSynchronization(completion: (() -> Void)?)
    /// Stops any ongoing synchronization
    func stopSynchronization()
}

extension SessionSynchronizer {
    func triggerSynchronization() {
        triggerSynchronization(completion: nil)
    }
}

// MARK: Namespacing struct

/// Namespace for session synchronization data objects
enum SessionsSynchronization { }

#if DEBUG
struct DummySessionSynchronizer: SessionSynchronizer {
    func triggerSynchronization(completion: (() -> Void)?) { completion?() }
    func stopSynchronization() { }
}
#endif
