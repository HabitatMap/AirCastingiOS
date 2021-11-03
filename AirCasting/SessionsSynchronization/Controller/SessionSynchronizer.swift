// Created by Lunar on 16/06/2021.
//

import Foundation
import Combine

/// Defines the interface for objects that provide session list synchronization to the app
protocol SessionSynchronizer {
    var syncInProgress: CurrentValueSubject<Bool, Never> { get }
    /// Triggers a new synchronization pass
    /// - Parameter completion: closure called when sycnhronization finishes
    func triggerSynchronization(completion: (() -> Void)?)
    /// Stops any ongoing synchronization
    func stopSynchronization()
    /// A plugin point for anyone interested in generated errors
    var errorStream: SessionSynchronizerErrorStream? { get set }
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
    var syncInProgress: CurrentValueSubject<Bool, Never> = .init(false)
    var errorStream: SessionSynchronizerErrorStream?
    func triggerSynchronization(completion: (() -> Void)?) { completion?() }
    func stopSynchronization() { }
}
#endif
