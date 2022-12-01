// Created by Lunar on 01/12/2022.
//

import Foundation
import Resolver
import CoreData

protocol SessionFollowingStorage {
    func accessStorage(_ task: @escaping(HiddenSessionFollowingStorage) -> Void)
}

protocol HiddenSessionFollowingStorage {
    func save() throws
    func updateSessionFollowing(_ sessionFollowing: SessionFollowing, for sessionUUID: SessionUUID)
}

class DefaultSessionFollowingStorage: SessionFollowingStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenSessionFollowingStorage = DefaultHiddenSessionFollowingStorage(context: self.context)
    
    /// All actions performed on HiddenSessionFollowingStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenSessionFollowingStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}


class DefaultHiddenSessionFollowingStorage: HiddenSessionFollowingStorage {
    @Injected private var updateSessionParamsService: UpdateSessionParamsService
    private let context: NSManagedObjectContext
    
    enum Error: Swift.Error {
        case missingSensorName
    }
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func save() throws {
        guard context.hasChanges else { return }
        try self.context.save()
    }
    
    func updateSessionFollowing(_ sessionFollowing: SessionFollowing, for sessionUUID: SessionUUID) {
        do {
            let sessionEntity = try context.existingSession(uuid: sessionUUID)
            if sessionFollowing == SessionFollowing.following {
                sessionEntity.followedAt = DateBuilder.getFakeUTCDate()
            } else {
                sessionEntity.followedAt = nil
                if let ui = sessionEntity.userInterface {
                    context.delete(ui)
                }
            }
            try context.save()
        } catch {
            Log.error("Error when saving changes in session: \(error.localizedDescription)")
        }
    }
}
