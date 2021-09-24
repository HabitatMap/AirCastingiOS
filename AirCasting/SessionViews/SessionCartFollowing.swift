// Created by Lunar on 29/07/2021.
//

import Foundation

protocol SessionFollowingSettable {
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
     private let measurementStreamStorage: MeasurementStreamStorage
     private let session: SessionEntity

     init(session: SessionEntity, measurementStreamStorage: MeasurementStreamStorage) {
         self.measurementStreamStorage = measurementStreamStorage
         self.session = session
     }

     var following: SessionFollowing {
         get {
             return session.followedAt != nil ? .following : .notFollowing
         }
         set {
             #warning("❌This 'setter' is asynchronous!!!")
             let id = self.session.uuid!
             measurementStreamStorage.accessStorage { storage in
                 storage.updateSessionFollowing(newValue, for: id)
             }
         }
     }
 }

 #if DEBUG
 class MockSessionFollowingSettable: SessionFollowingSettable {
     var following: SessionFollowing = .notFollowing
 }
 #endif
