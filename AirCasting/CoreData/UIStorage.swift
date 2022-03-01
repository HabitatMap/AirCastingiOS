// Created by Lunar on 10/02/2022.
//

import CoreData
import Resolver

protocol UIStorage {
    func accessStorage(_ task: @escaping(HiddenCoreDataUIStorage) -> Void)
}

protocol UIStorageContextUpdate {
    func cardStateToggle(for sessionUUID: SessionUUID) throws
    func changeStream(for sessionUUID: SessionUUID, stream: String) throws
    func save() throws
}

final class CoreDataUIStorage: UIStorage {
    
    private let context: NSManagedObjectContext
    private lazy var updateSessionParamsService = UpdateSessionParamsService()
    private lazy var hiddenStorage = HiddenCoreDataUIStorage(context: self.context)
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// All actions performed on CoreDataMeasurementStreamStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenCoreDataUIStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

final class HiddenCoreDataUIStorage: UIStorageContextUpdate {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func cardStateToggle(for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        createUIStateIfNeeded(entity: sessionEntity)
        sessionEntity.userInterface?.expandedCard.toggle()
    }
    
    func changeStream(for sessionUUID: SessionUUID, stream: String) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        createUIStateIfNeeded(entity: sessionEntity)
        sessionEntity.userInterface?.sensorName = stream
    }
    
    private func createUIStateIfNeeded(entity: SessionEntity) {
        if entity.userInterface == nil {
            let uiState = UIStateEntity(context: context)
            uiState.session = entity
        }
    }
    
    func save() throws {
        try self.context.save()
    }
}