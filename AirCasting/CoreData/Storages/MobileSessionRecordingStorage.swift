// Created by Lunar on 18/11/2022.
//

import Foundation
import Resolver
import CoreData
import CoreLocation

protocol MobileSessionRecordingStorage {
    func accessStorage(_ task: @escaping(HiddenMobileSessionRecordingStorage) -> Void)
}

protocol HiddenMobileSessionRecordingStorage {
    func save() throws
    func createSession(_ session: Session) throws -> SessionEntity
    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws
    func saveMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID
    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID?
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D?, toStreamWithID id: MeasurementStreamLocalID, on time: Date) throws
    /// Bulk-append measurement values across one or more streams in a single
    /// context transaction. Caller resolves the `streamID` per entry. Used by
    /// the V2 active-sync replay path so a chunk of ~100 records lands in one
    /// CoreData save instead of ~200 individual saves.
    func appendMeasurementValues(_ entries: [(streamID: MeasurementStreamLocalID,
                                              value: Double,
                                              time: Date,
                                              location: CLLocationCoordinate2D?)]) throws
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws
}

class DefaultMobileSessionRecordingStorage: MobileSessionRecordingStorage {
    @Injected private var persistenceController: PersistenceController
    private lazy var context: NSManagedObjectContext = persistenceController.editContext
    private lazy var hiddenStorage: HiddenMobileSessionRecordingStorage = DefaultHiddenMobileSessionRecordingStorage(context: self.context)
    
    /// All actions performed on HiddenMobileSessionRecordingStorage must be performed
    /// within a block passed to this methood.
    /// This ensures thread-safety by dispatching all calls to the queue owned by the NSManagedObjectContext.
    func accessStorage(_ task: @escaping(HiddenMobileSessionRecordingStorage) -> Void) {
        context.perform {
            task(self.hiddenStorage)
            try? self.hiddenStorage.save()
        }
    }
}

class DefaultHiddenMobileSessionRecordingStorage: HiddenMobileSessionRecordingStorage {
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
    
    @discardableResult
    func createSession(_ session: Session) throws -> SessionEntity {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        return sessionEntity
    }
    
    func createSessionAndMeasurementStream(_ session: Session, _ stream: MeasurementStream) throws {
        let sessionEntity = newSessionEntity()
        updateSessionParamsService.updateSessionsParams(sessionEntity, session: session)
        _ = try saveMeasurementStream(for: sessionEntity, context: context, stream)
    }
    
    func existingMeasurementStream(_ sessionUUID: SessionUUID, name: String) throws -> MeasurementStreamLocalID? {
        let session = try context.existingSession(uuid: sessionUUID)
        let stream = session.streamWith(sensorName: name)
        return stream?.localID
    }
    
    func addMeasurementValue(_ value: Double, at location: CLLocationCoordinate2D? = nil, toStreamWithID id: MeasurementStreamLocalID, on time: Date = DateBuilder.getRawDate().currentUTCTimeZoneDate) throws {
        try addMeasurement(Measurement(time: time, value: value, location: location), toStreamWithID: id)
    }

    func appendMeasurementValues(_ entries: [(streamID: MeasurementStreamLocalID,
                                              value: Double,
                                              time: Date,
                                              location: CLLocationCoordinate2D?)]) throws {
        guard !entries.isEmpty else { return }
        // Resolve every DISTINCT stream up front, before inserting any measurement.
        // `existingObject(with:)` throws (CoreData 133000) if a stream's objectID is
        // no longer in the store — e.g. a stale/temporary id. Doing all the lookups
        // first keeps a failing batch atomic: it throws with ZERO measurements
        // inserted, so the caller can clear its id cache, re-resolve, and retry
        // without risking duplicate rows (which would then trip the
        // (measurementStream,time) uniqueness constraint).
        var streamCache: [NSManagedObjectID: MeasurementStreamEntity] = [:]
        for id in Set(entries.map { $0.streamID.id }) {
            streamCache[id] = try context.existingObject(with: id) as! MeasurementStreamEntity
        }
        for entry in entries {
            let streamEntity = streamCache[entry.streamID.id]!
            let newMeasurement = MeasurementEntity(context: context)
            newMeasurement.location = entry.location
            newMeasurement.time = entry.time
            newMeasurement.value = entry.value
            streamEntity.addToMeasurements(newMeasurement)
        }
    }
    
    func saveMeasurementStream(_ stream: MeasurementStream, for sessionUUID: SessionUUID) throws -> MeasurementStreamLocalID {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        return try saveMeasurementStream(for: sessionEntity, context: context, stream)
    }
    
    func updateSessionStatus(_ sessionStatus: SessionStatus, for sessionUUID: SessionUUID) throws {
        let sessionEntity = try context.existingSession(uuid: sessionUUID)
        sessionEntity.status = sessionStatus
    }
    
    private func addMeasurement(_ measurement: Measurement, toStreamWithID id: MeasurementStreamLocalID) throws {
        let stream = try context.existingObject(with: id.id) as! MeasurementStreamEntity

        let newMeasurement = MeasurementEntity(context: context)
        newMeasurement.location = measurement.location
        newMeasurement.time = measurement.time
        newMeasurement.value = measurement.value
        stream.addToMeasurements(newMeasurement)
    }
    
    private func newSessionEntity() -> SessionEntity {
        let sessionEntity = SessionEntity(context: context)
        let uiState = UIStateEntity(context: context)
        uiState.session = sessionEntity
        return sessionEntity
    }
    
    private func saveMeasurementStream(for session: SessionEntity, context: NSManagedObjectContext, _ stream: MeasurementStream) throws -> MeasurementStreamLocalID {
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

        guard let sensorName = stream.sensorName else {
            throw Error.missingSensorName
        }
        
        let existingThreshold: SensorThreshold? = try context.existingObject(sensorName: sensorName)
        if existingThreshold == nil {
            let threshold: SensorThreshold = try context.newOrExisting(sensorName: sensorName)
            threshold.thresholdVeryLow = stream.thresholdVeryLow
            threshold.thresholdLow = stream.thresholdLow
            threshold.thresholdMedium = stream.thresholdMedium
            threshold.thresholdHigh = stream.thresholdHigh
            threshold.thresholdVeryHigh = stream.thresholdVeryHigh
        }

        // A freshly-inserted object carries a TEMPORARY objectID until a save reaches
        // the persistent store. Callers (notably the V2 sync path's v2SyncStreamCache)
        // cache this `localID` and resolve it later via `existingObject(with:)`. A
        // temporary objectID is invalidated the moment the context is refreshed
        // (`refreshAllObjects()` from the shared-editContext averaging save), after
        // which the cached id throws CoreData 133000 "object not found in store" and
        // every subsequent measurement batch is silently dropped — the missing-middle
        // data loss. Mint a permanent id now so the cached id stays resolvable.
        try context.obtainPermanentIDs(for: [newStream])

        return newStream.localID
    }
}
