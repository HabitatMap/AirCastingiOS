// Created by Lunar on 30/11/2022.
//

import Foundation
import Resolver
import CoreData

protocol SDSyncMeasurementsStorage {
    func accessStorage(_ task: @escaping(HiddenSDSyncMeasurementsStorage) -> Void)
}

protocol HiddenSDSyncMeasurementsStorage {
    func save() throws
    func getExistingSession(with sessionUUID: SessionUUID) throws -> SessionEntity
    func removeDuplicatedMeasurements(for sessionUUID: SessionUUID) throws
}

class DefaultSDSyncMeasurementsStorage: SDSyncMeasurementsStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenSDSyncMeasurementsStorage = DefaultHiddenSDSyncMeasurementsStorage(context: self.context)
    
    /// All actions performed on DefaultSDSyncMeasurementsStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenSDSyncMeasurementsStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

class DefaultHiddenSDSyncMeasurementsStorage: HiddenSDSyncMeasurementsStorage {
    private let context: NSManagedObjectContext

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
    
    func removeDuplicatedMeasurements(for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.allStreams.forEach({ stream in
            guard let measurements = stream.allMeasurements else { return }
            let sortedMeasurements = measurements.sorted(by: { $0.time < $1.time })
            for (i, measurement) in sortedMeasurements.enumerated() {
                if i > 0 {
                    if measurement.time.roundedDownToSecond == sortedMeasurements[i-1].time.roundedDownToSecond {
                        context.delete(measurement)
                    }
                }
            }
        })
        Log.info("Deleted duplicated measurements")
    }
}
