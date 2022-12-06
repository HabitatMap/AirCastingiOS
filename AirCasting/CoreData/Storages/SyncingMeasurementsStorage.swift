// Created by Lunar on 01/12/2022.
//

import Foundation
import Resolver
import CoreData
import CoreLocation

protocol SyncingMeasurementsStorage {
    func accessStorage(_ task: @escaping(HiddenSyncingMeasurementsStorage) -> Void)
}

protocol HiddenSyncingMeasurementsStorage {
    func save() throws
    func updateSessionEndTimeWithoutUTCConversion(_ endTime: Date, for sessionUUID: SessionUUID) throws
    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamEntity?
    func saveThresholdFor(sensorName: String, thresholdVeryHigh: Int32, thresholdHigh: Int32, thresholdMedium: Int32, thresholdLow: Int32, thresholdVeryLow: Int32) throws
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D?, toStream stream: MeasurementStreamEntity, on time: Date) throws
}

class DefaultSyncingMeasurementsStorage: SyncingMeasurementsStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenSyncingMeasurementsStorage = DefaultHiddenSyncingMeasurementsStorage(context: self.context)
    
    /// All actions performed on HiddenSyncingMeasurementsStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenSyncingMeasurementsStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

class DefaultHiddenSyncingMeasurementsStorage: HiddenSyncingMeasurementsStorage {
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
    
    func updateSessionEndTimeWithoutUTCConversion(_ endTime: Date, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.endTime = endTime
    }
    
    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamEntity? {
        let session = try context.existingSession(uuid: sessionUUID)
        let stream = session.streamWith(sensorName: name)
        return stream
    }
    
    func saveThresholdFor(sensorName: String, thresholdVeryHigh: Int32, thresholdHigh: Int32, thresholdMedium: Int32, thresholdLow: Int32, thresholdVeryLow: Int32) throws {
        let existingThreshold: SensorThreshold? = try context.existingObject(sensorName: sensorName)
        if existingThreshold == nil {
            let threshold: SensorThreshold = try context.newOrExisting(sensorName: sensorName)
            threshold.thresholdVeryLow = thresholdVeryLow
            threshold.thresholdLow = thresholdLow
            threshold.thresholdMedium = thresholdMedium
            threshold.thresholdHigh = thresholdHigh
            threshold.thresholdVeryHigh = thresholdVeryHigh
        }
    }
    
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D? = .undefined, toStream stream: MeasurementStreamEntity, on time: Date) throws {
        try addMeasurement(Measurement(time: time, value: value, location: location), toStream: stream)
    }
    
    private func addMeasurement(_ measurement: Measurement, toStream stream: MeasurementStreamEntity) throws {
        let newMeasurement = MeasurementEntity(context: context)
        newMeasurement.location = measurement.location
        newMeasurement.time = measurement.time
        newMeasurement.value = measurement.value
        stream.addToMeasurements(newMeasurement)
    }
}
