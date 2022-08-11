// Created by Lunar on 09/08/2022.
//
import CoreData
import Resolver

protocol SessionStorage {
    func accessStorage(_ task: @escaping(HiddenCoreDataSessionStorage) -> Void)
}

protocol SessionStorageContextUpdate {
    func clearBluetoothPeripheralUUID(_ sessionUUID: SessionUUID) throws
    func save() throws
}

final class CoreDataSessionStorage: SessionStorage {
    
    private let context: NSManagedObjectContext
    private lazy var updateSessionParamsService = UpdateSessionParamsService()
    private lazy var hiddenStorage = HiddenCoreDataSessionStorage(context: self.context)
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// All actions performed on CoreDataMeasurementStreamStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenCoreDataSessionStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

final class HiddenCoreDataSessionStorage: SessionStorageContextUpdate {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func clearBluetoothPeripheralUUID(_ sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        guard let bluetoothConnection = sessionEntity.bluetoothConnection else { return }
        bluetoothConnection.peripheralUUID = ""
    }

    func save() throws {
        try self.context.save()
    }
}
