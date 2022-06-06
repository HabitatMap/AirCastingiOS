// Created by Lunar on 29/07/2021.
//

import Foundation
import Resolver

protocol SessionFollowingSettable {
    /// Sets the following state of the receiver.
    /// Note that its setter can be asynchronous.
     var following: SessionFollowing { get set }
 }

extension SessionFollowing {
     func toggled() -> Self {
         switch self {
         case .following: return .notFollowing
         case .notFollowing: return .following
         }
     }
 }

class MeasurementStreamStorageFollowingSettable: SessionFollowingSettable {
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    @Injected private var uiStorage: UIStorage
    private let session: SessionEntity
    
    init(session: SessionEntity) {
        self.session = session
    }
    
    var following: SessionFollowing {
        get {
            return session.followedAt != nil ? .following : .notFollowing
        }
        set {
            let id = self.session.uuid!
            measurementStreamStorage.accessStorage { [sessionId = session.uuid, uiStorage] storage in
                Log.info("\(newValue == .following ? "Following" : "Unfollowing") session [\(sessionId ?? "NONE")]")
                storage.updateSessionFollowing(newValue, for: id)
                // TODO: Use this `SessionFollowingSettable` mechanism for external sesions too!
                uiStorage.accessStorage { uiStorage in
                    if newValue == .following {
                        uiStorage.giveHighestOrder(to: id)
                    } else {
                        uiStorage.setOrderToZero(for: id)
                    }
                }
            }
        }
    }
}

 #if DEBUG
 class MockSessionFollowingSettable: SessionFollowingSettable {
     var following: SessionFollowing = .notFollowing
 }
 #endif
