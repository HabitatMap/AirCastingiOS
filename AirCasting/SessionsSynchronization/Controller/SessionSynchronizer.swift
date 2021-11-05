// Created by Lunar on 16/06/2021.
//

import Foundation
import Combine

struct SessionSynchronizationOptions: OptionSet {
    /// Downloads and saves sessions not present on device
    static let download = SessionSynchronizationOptions(rawValue: 1)
    /// Uploads sessions that are not present on remote server
    static let upload = SessionSynchronizationOptions(rawValue: 1 << 1)
    /// Removes sessions that have been removed from remote server
    static let remove = SessionSynchronizationOptions(rawValue: 1 << 2)
    
    let rawValue: Int8
}

/// Defines the interface for objects that provide session list synchronization to the app
protocol SessionSynchronizer {
    var syncInProgress: CurrentValueSubject<Bool, Never> { get }
    /// Triggers a new synchronization pass
    /// - Parameter completion: closure called when sycnhronization finishes
    func triggerSynchronization(options: SessionSynchronizationOptions, completion: (() -> Void)?)
    /// Stops any ongoing synchronization
    func stopSynchronization()
    /// A plugin point for anyone interested in generated errors
    var errorStream: SessionSynchronizerErrorStream? { get set }
}

extension SessionSynchronizer {
    func triggerSynchronization(options: SessionSynchronizationOptions) {
        triggerSynchronization(options: options, completion: nil)
    }
    
    func triggerSynchronization() {
        triggerSynchronization(options: [.download, .upload, .remove], completion: nil)
    }
}

// MARK: Namespacing struct

/// Namespace for session synchronization data objects
enum SessionsSynchronization { }

#if DEBUG
struct DummySessionSynchronizer: SessionSynchronizer {
    var syncInProgress: CurrentValueSubject<Bool, Never> = .init(false)
    var errorStream: SessionSynchronizerErrorStream?
    func triggerSynchronization(options: SessionSynchronizationOptions, completion: (() -> Void)?) { completion?() }
    func stopSynchronization() { }
}
#endif
