// Created by Lunar on 18/11/2022.
//

import Foundation
import Resolver
import CoreData

protocol MobileSessionFinishingStorage {
    func accessStorage(_ task: @escaping(HiddenMobileSessionFinishingStorage) -> Void)
}

protocol HiddenMobileSessionFinishingStorage {
    func save() throws
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws
    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws
}

class DefaultMobileSessionFinishingStorage: MobileSessionFinishingStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenMobileSessionFinishingStorage = DefaultHiddenMobileSessionFinishingStorage(context: self.context)
    
    /// All actions performed on HiddenMobileSessionFinishingStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenMobileSessionFinishingStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

class DefaultHiddenMobileSessionFinishingStorage: HiddenMobileSessionFinishingStorage {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func save() throws {
        guard context.hasChanges else { return }
        try self.context.save()
    }
    
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.status = sessionStatus
    }
    
    func updateSessionEndtime(_ endTime: Date, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.endTime = endTime.currentUTCTimeZoneDate
    }
}
