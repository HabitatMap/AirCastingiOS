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
    func switchCardExpanded(to newValue: Bool, sessionUUID: SessionUUID) throws 
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
        if let sessionEntity = try? context.existingExternalSession(uuid: sessionUUID) {
            createUIStateIfNeededForExternalSession(entity: sessionEntity)
            sessionEntity.userInterface?.expandedCard.toggle()
            return
        }
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        createUIStateIfNeeded(entity: sessionEntity)
        sessionEntity.userInterface?.expandedCard.toggle()
    }
    
    func switchCardExpanded(to newValue: Bool, sessionUUID: SessionUUID) throws {
        if let sessionEntity = try? context.existingExternalSession(uuid: sessionUUID) {
            createUIStateIfNeededForExternalSession(entity: sessionEntity)
            sessionEntity.userInterface?.expandedCard = newValue
            return
        }
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        createUIStateIfNeeded(entity: sessionEntity)
        sessionEntity.userInterface?.expandedCard = newValue
    }
    
    func changeStream(for sessionUUID: SessionUUID, stream: String) throws {
        if let sessionEntity = try? context.existingSession(uuid: sessionUUID) {
            createUIStateIfNeeded(entity: sessionEntity)
            sessionEntity.userInterface?.sensorName = stream
            return
        }
        
        let sessionEntity = try context.existingExternalSession(uuid: sessionUUID)
        createUIStateIfNeededForExternalSession(entity: sessionEntity)
        sessionEntity.userInterface?.sensorName = stream
    }
    
    // MARK: Session ordering
    
    func updateSessionOrder(_ order: Int, for sessionUUID: SessionUUID) {
        do {
            guard let session = try context.existingSessionable(uuid: sessionUUID) else {
                Log.error("Trying to update order for nonexistent session [\(sessionUUID)]")
                return
            }
            createUIStateIfNeededForSessionable(session)
            session.userInterface?.rowOrder = Int64(order)
            try context.save()
        } catch {
            Log.error("Error when saving changes in session: \(error.localizedDescription)")
        }
    }

    func giveHighestOrder(to sessionUUID: SessionUUID) {
        do {
            guard let session = try context.existingSessionable(uuid: sessionUUID) else {
                Log.error("Trying to update order for nonexistent session [\(sessionUUID)]")
                return
            }
            createUIStateIfNeededForSessionable(session)
            let highestOrder = try context.getHighestRowOrder()
            session.userInterface?.rowOrder = (highestOrder ?? 0) + 1
            try context.save()
        } catch {
            Log.error("Error when saving changes in session: \(error.localizedDescription)")
        }
    }

    func setOrderToZero(for sessionUUID: SessionUUID) {
        do {
            guard let session = try context.existingSessionable(uuid: sessionUUID) else {
                Log.error("Trying to update order for nonexistent session [\(sessionUUID)]")
                return
            }
            session.userInterface?.rowOrder = 0
            try context.save()
        } catch {
            Log.error("Error when saving changes in session: \(error.localizedDescription)")
        }
    }
    
    private func createUIStateIfNeeded(entity: SessionEntity) {
        if entity.userInterface == nil {
            let uiState = UIStateEntity(context: context)
            uiState.session = entity
        }
    }
    
    private func createUIStateIfNeededForExternalSession(entity: ExternalSessionEntity) {
        if entity.userInterface == nil {
            let uiState = UIStateEntity(context: context)
            uiState.externalSession = entity
        }
    }
    
    private func createUIStateIfNeededForSessionable(_ sessionable: Sessionable) {
        if let sessionEntity = sessionable as? SessionEntity {
            guard sessionable.userInterface == nil else { return }
            let uiState = UIStateEntity(context: context)
            uiState.session = sessionEntity
        } else if let externalEntity = sessionable as? ExternalSessionEntity {
            guard externalEntity.userInterface == nil else { return }
            let uiState = UIStateEntity(context: context)
            uiState.externalSession = externalEntity
        }
    }
    
    func save() throws {
        try self.context.save()
    }
}
