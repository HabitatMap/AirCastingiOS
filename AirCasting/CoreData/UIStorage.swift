// Created by Lunar on 10/02/2022.
//

import CoreData
import Combine
import SwiftUI
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
    
    @Injected private var persistenceController: PersistenceController
    private lazy var updateSessionParamsService = UpdateSessionParamsService()
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage = HiddenCoreDataUIStorage(context: self.context)
    
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
        checkUIStateAvaibility(entity: sessionEntity)
        sessionEntity.userInterface?.expandedCard.toggle()
        try context.save()
    }
    
    func changeStream(for sessionUUID: SessionUUID, stream: String) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        checkUIStateAvaibility(entity: sessionEntity)
        sessionEntity.userInterface?.sensorName = stream
        try context.save()
    }
    
    private func checkUIStateAvaibility(entity: SessionEntity) {
        if entity.userInterface == nil {
            let UIState = UIStateEntity(context: context)
            UIState.session = entity
        }
    }
    
    func save() throws {
        try self.context.save()
    }
}
