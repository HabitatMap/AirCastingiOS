// Created by Lunar on 25/07/2021.
//

import Foundation

/// Error type for sessions synchronization
enum SessionSynchronizerError: Error, Equatable {
    case noConnection
    case cannotFetchLocalData
    case cannotFetchSyncContext
    case downloadFailed(SessionUUID)
    case storeWriteFailure([SessionUUID])
    case uploadFailure(SessionUUID)
    case storeReadFailure(SessionUUID)
    case storeDeleteFailure([SessionUUID])
    case unknown
}

/// Defines the interface for objects that can handle session synchronization errors
protocol SessionSynchronizerErrorStream {
    /// This method is being called when any error occurs during sesisons synchronization process
    /// - Parameter : A `SessionSynchronizerError` describing what happened
    func handleSyncError(_: SessionSynchronizerError)
}
