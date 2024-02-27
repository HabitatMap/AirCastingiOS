// Created by Lunar on 29/09/2022.
//

import Foundation
import CoreData
import CoreLocation
import Resolver

struct SDSyncMobileSessionsDatabaseStorage {
    @Injected private var updateSessionParamsService: UpdateSessionParamsService
    
    func addMeasurement(to stream: MeasurementStreamEntity, measurement: AverageableMeasurement, averagingWindow: AveragingWindow, context: NSManagedObjectContext) {
        let newMeasurement = MeasurementEntity(context: context)
        newMeasurement.location = measurement.location
        newMeasurement.time = measurement.measuredAt
        newMeasurement.value = measurement.value
        newMeasurement.averagingWindow = averagingWindow.rawValue
        stream.addToMeasurements(newMeasurement)
    }
    
    func setStatusToFinishedAndUpdateEndTime(for sessionUUID: SessionUUID, context: NSManagedObjectContext) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.status = .FINISHED
        guard let endTime = sessionEntity.lastMeasurementTime else { return }
        Log.info("SD Sync end time for session (UUID | name) \(sessionEntity.uuid) \(sessionEntity.name ?? ""): \(endTime)")
        sessionEntity.endTime = endTime
    }
    
    func fetchUnaveragedMeasurements(currentWindow: AveragingWindow, stream: MeasurementStreamEntity, context: NSManagedObjectContext) throws -> [MeasurementEntity] {
        let fetchRequest = fetchRequestForUnaveragedMeasurements(currentWindow: currentWindow, stream: stream)
        return try context.fetch(fetchRequest)
    }
    
    private func fetchRequestForUnaveragedMeasurements(currentWindow: AveragingWindow, stream: MeasurementStreamEntity) -> NSFetchRequest<MeasurementEntity> {
        let fetchRequest = MeasurementEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "averagingWindow != %d AND measurementStream == %@", currentWindow.rawValue, stream)
        return fetchRequest
    }
    
    func sortAllMeasurements(stream: MeasurementStreamEntity, context: NSManagedObjectContext) throws {
        let fetchRequest = MeasurementEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "measurementStream == %@", stream)
        let measurements = try context.fetch(fetchRequest)
        stream.measurements = NSOrderedSet(array: measurements)
        try context.save()
    }
    
    func createSession(uuid: SessionUUID, location: CLLocationCoordinate2D?, time: Date?, context: NSManagedObjectContext) -> SessionEntity {
        Log.info("[SD Sync] Creating session: \(uuid)")
        let session = Session(uuid: uuid, type: .mobile, name: "Imported from AirBeam storage", deviceType: .AIRBEAM3, location: location, startTime: time)
        let sessionEntity = newSessionEntity(context: context)
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        return sessionEntity
    }
    
    private func newSessionEntity(context: NSManagedObjectContext) -> SessionEntity {
        let sessionEntity = SessionEntity(context: context)
        let uiState = UIStateEntity(context: context)
        uiState.session = sessionEntity
        return sessionEntity
    }
    
    func createMeasurementStream(for session: SessionEntity, sensorName: MeasurementStreamSensorName, deviceID: String, context: NSManagedObjectContext) throws -> MeasurementStreamEntity {
        let stream = MeasurementStream(sensorName: sensorName, sensorPackageName: deviceID)
        
        let newStream = MeasurementStreamEntity(context: context)
        newStream.sensorName = stream.sensorName
        newStream.sensorPackageName = stream.sensorPackageName
        newStream.measurementType = stream.measurementType
        newStream.measurementShortType = stream.measurementShortType
        newStream.unitName = stream.unitName
        newStream.unitSymbol = stream.unitSymbol
        newStream.thresholdVeryLow = stream.thresholdVeryLow
        newStream.thresholdLow = stream.thresholdLow
        newStream.thresholdMedium = stream.thresholdMedium
        newStream.thresholdHigh = stream.thresholdHigh
        newStream.thresholdVeryHigh = stream.thresholdVeryHigh
        newStream.gotDeleted = false
        
        session.addToMeasurementStreams(newStream)
        
        let existingThreshold: SensorThreshold? = try context.existingObject(sensorName: sensorName.rawValue)
        if existingThreshold == nil {
            let threshold: SensorThreshold = try context.newOrExisting(sensorName: sensorName.rawValue)
            threshold.thresholdVeryLow = stream.thresholdVeryLow
            threshold.thresholdLow = stream.thresholdLow
            threshold.thresholdMedium = stream.thresholdMedium
            threshold.thresholdHigh = stream.thresholdHigh
            threshold.thresholdVeryHigh = stream.thresholdVeryHigh
        }
        
        return newStream
    }
}
