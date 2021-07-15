// Created by Lunar on 16/06/2021.
//

import Foundation
import Combine

/// Defines interface for objects which provide local session context for sync process
///
/// Overview of the sync process:
/// 1. Fetch sessions stored locally on a device
/// 2. Diff them against global database (this interface)
/// 3. Download/Upload/Delete accordingly
protocol SessionSynchronizationContextProvidable {
    func getSynchronizationContext(localSessions: [SessionsSynchronization.Metadata]) -> AnyPublisher<SessionsSynchronization.SynchronizationContext, Error>
}

// MARK: Data structures

extension SessionsSynchronization {
    struct SynchronizationContext: Equatable, Decodable {
        let needToBeDownloaded: [SessionUUID]
        let needToBeUploaded: [SessionUUID]
        let removed: [SessionUUID]
        
        enum CodingKeys: String, CodingKey {
            case needToBeDownloaded = "download"
            case needToBeUploaded = "upload"
            case removed = "deleted"
        }
    }
}
