// Created by Lunar on 01/12/2022.
//

import Foundation
import Resolver
import CoreData

protocol SessionCreatingStorage {
    func accessStorage(_ task: @escaping(HiddenSessionCreatingStorage) -> Void)
}

protocol HiddenSessionCreatingStorage {
    func save() throws
    func createSession(_ session: Session) throws
    /// Stamp the just-created session's `BluetoothConnectionEntity` with the
    /// firmware version and the BLE peripheral identifier so downstream code
    /// (notably `SessionEntity.deviceFirmwareVersion`) can route by V1 vs V2.
    /// V2 fixed sessions don't go through `MeasurementsSavingService.createSession`
    /// (the only other site that builds this entity), so without this hook the
    /// V1-default fallback masks them as V1 — which then double-shifts the
    /// indoor BE-timestamp round-trip.
    func stampBluetoothConnection(sessionUUID: SessionUUID, peripheralUUID: String, firmwareVersion: FirmwareVersion) throws
}

class DefaultSessionCreatingStorage: SessionCreatingStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenSessionCreatingStorage = DefaultHiddenSessionCreatingStorage(context: self.context)
    
    /// All actions performed on HiddenSessionCreatingStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenSessionCreatingStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

class DefaultHiddenSessionCreatingStorage: HiddenSessionCreatingStorage {
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
    
    func createSession(_ session: Session) throws {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
    }

    func stampBluetoothConnection(sessionUUID: SessionUUID, peripheralUUID: String, firmwareVersion: FirmwareVersion) throws {
        let entity: SessionEntity = try context.existingSession(uuid: sessionUUID)
        let connection = entity.bluetoothConnection ?? BluetoothConnectionEntity(context: context)
        connection.peripheralUUID = peripheralUUID
        connection.firmwareVersionRaw = Int16(firmwareVersion == .v2 ? 1 : 0)
        connection.session = entity
    }

    private func newSessionEntity() -> SessionEntity {
        let sessionEntity = SessionEntity(context: context)
        let uiState = UIStateEntity(context: context)
        uiState.session = sessionEntity
        return sessionEntity
    }
}
