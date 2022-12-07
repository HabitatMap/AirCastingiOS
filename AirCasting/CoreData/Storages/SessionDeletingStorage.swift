// Created by Lunar on 30/11/2022.
//

import Foundation
import Resolver
import CoreData

protocol SessionDeletingStorage {
    func accessStorage(_ task: @escaping(HiddenSessionDeletingStorage) -> Void)
}

protocol HiddenSessionDeletingStorage {
    func save() throws
    func markSessionForDelete(_ sessionUUID: SessionUUID) throws
    func markStreamForDelete(_ sessionUUID: SessionUUID, sensorsName: [String], completion: () -> Void) throws
    func deleteStreams(_ sessionUUID: SessionUUID) throws
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity
    func updateVersion(for sessionUUID: SessionUUID, to version: Int) throws
}

class DefaultSessionDeletingStorage: SessionDeletingStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenSessionDeletingStorage = DefaultHiddenSessionDeletingStorage(context: self.context)

    /// All actions performed on DefaultSessionDeletingStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenSessionDeletingStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

class DefaultHiddenSessionDeletingStorage: HiddenSessionDeletingStorage {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func save() throws {
        guard context.hasChanges else { return }
        try self.context.save()
    }
    
    func markSessionForDelete(_ sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.gotDeleted = true
    }
    
    func markStreamForDelete(_ sessionUUID: SessionUUID, sensorsName: [String], completion: () -> Void) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sensorsName.forEach { sensorName in
            guard let stream = sessionEntity.allStreams.first(where: { $0.sensorName == sensorName }) else {
                Log.info("Error when trying to hide measurement streams")
                return
            }
            stream.gotDeleted = true
            forceUpdate(sessionEntity: sessionEntity)
        }
        completion()
    }
    
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity {
        let session = try context.existingSession(uuid: sessionUUID)
        return session
    }
    
    func deleteStreams(_ sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        let toDelete = sessionEntity.allStreams.filter({ $0.gotDeleted })
        toDelete.forEach { object in
            context.delete(object)
        }
        forceUpdate(sessionEntity: sessionEntity)
    }
    
    func updateVersion(for sessionUUID: SessionUUID, to version: Int) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.version = Int16(version)
    }
    
    private func forceUpdate(sessionEntity: SessionEntity) {
        sessionEntity.changesCount += 1
        // EXPLANATION for above line:
        // We basically force core data to send change notifications for this Session objects in the app
        // because the NSOrderedSet operations don't trigger KVO and thus don't trigger ObservableObject changes
    }
}
