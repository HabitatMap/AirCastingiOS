// Created by Lunar on 01/12/2022.
//

import Foundation
import Resolver
import CoreData

protocol SessionEditingStorage {
    func accessStorage(_ task: @escaping(HiddenSessionEditingStorage) -> Void)
}

protocol HiddenSessionEditingStorage {
    func save() throws
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity
    func updateSessionNameAndTags(name: String, tags: String, for sessionUUID: SessionUUID) throws
    func updateVersion(for sessionUUID: SessionUUID, to version: Int) throws
}

class DefaultSessionEditingStorage: SessionEditingStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenSessionEditingStorage = DefaultHiddenSessionEditingStorage(context: self.context)
    
    /// All actions performed on HiddenSessionEditingStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenSessionEditingStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}


class DefaultHiddenSessionEditingStorage: HiddenSessionEditingStorage {
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
    
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity {
        let session = try context.existingSession(uuid: sessionUUID)
        return session
    }
    
    func updateSessionNameAndTags(name: String, tags: String, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.name = name
        sessionEntity.tags = tags
    }
    
    func updateVersion(for sessionUUID: SessionUUID, to version: Int) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.version = Int16(version)
    }
}
