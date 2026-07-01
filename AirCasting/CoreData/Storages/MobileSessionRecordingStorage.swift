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
    /// Diagnostic: log the session's stored measurement coverage so a data gap
    /// can be classified from the log WITHOUT DB access on the user's device.
    /// Per stream logs total measurements, how many carry NO location (nil
    /// lat/long — these are dropped from the location-keyed CSV/map export), the
    /// stored time span, and the largest gap between consecutive stored rows.
    /// Reading the result: a large `nullLocation` with a small `largestGap` means
    /// the measurements EXIST but are location-less (export-excluded, recoverable);
    /// a large `largestGap` means rows are genuinely ABSENT for that span (never
    /// captured). Note `.undefined` (200,200) locationless rows count as located,
    /// not null — so `nullLocation` isolates the stale-fix holes.
    func logMeasurementCoverage(sessionUUID: SessionUUID)
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

    func logMeasurementCoverage(sessionUUID: SessionUUID) {
        do {
            let session = try context.existingSession(uuid: sessionUUID)
            let streams = session.allStreams
            guard !streams.isEmpty else {
                Log.info("[V2DIAG] coverage \(sessionUUID): no streams")
                return
            }
            for stream in streams {
                let streamName = stream.sensorName ?? "?"
                // Fetch only time + lat/long, no fault of the full entity graph,
                // sorted by time — cheap enough for a one-shot finish-time scan.
                let request = NSFetchRequest<NSManagedObject>(entityName: "MeasurementEntity")
                request.predicate = NSPredicate(format: "measurementStream == %@", stream)
                request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
                request.propertiesToFetch = ["time", "latitude", "longitude"]
                request.returnsObjectsAsFaults = false
                let rows = try context.fetch(request)
                guard !rows.isEmpty else {
                    Log.info("[V2DIAG] coverage \(sessionUUID) stream=\(streamName): 0 measurements")
                    continue
                }
                var nullLocation = 0
                var gaps: [(at: TimeInterval, dur: TimeInterval)] = []
                var totalGapSeconds: TimeInterval = 0
                var minDelta = TimeInterval.greatestFiniteMagnitude
                var prev: Date?
                var firstTS: TimeInterval = 0
                var lastTS: TimeInterval = 0
                for row in rows {
                    guard let t = row.value(forKey: "time") as? Date else { continue }
                    if prev == nil { firstTS = t.timeIntervalSince1970 }
                    lastTS = t.timeIntervalSince1970
                    let lat = row.value(forKey: "latitude") as? Double
                    let lon = row.value(forKey: "longitude") as? Double
                    if lat == nil || lon == nil { nullLocation += 1 }
                    if let p = prev {
                        let gap = t.timeIntervalSince(p)
                        if gap > 0 { minDelta = Swift.min(minDelta, gap) }
                        // >10s = more than a couple of missed native/averaged samples.
                        if gap > 10 { gaps.append((p.timeIntervalSince1970, gap)); totalGapSeconds += gap }
                    }
                    prev = t
                }
                // Expected count from the tightest observed cadence (minDelta ≈ the
                // native interval): a shortfall vs actual = time not covered by rows.
                let span = lastTS - firstTS
                let expected = (minDelta.isFinite && minDelta > 0) ? Int(span / minDelta) + 1 : rows.count
                // List every significant hole (largest first), not just the biggest.
                let topGaps = gaps.sorted { $0.dur > $1.dur }.prefix(8)
                    .map { "\(String(format: "%.0f", $0.dur))s@\(String(format: "%.0f", $0.at))" }
                    .joined(separator: ", ")
                Log.info("[V2DIAG] coverage \(sessionUUID) stream=\(streamName): measurements=\(rows.count) expected≈\(expected) nullLocation=\(nullLocation) span=[\(String(format: "%.0f", firstTS))…\(String(format: "%.0f", lastTS))] gaps>10s=\(gaps.count) totalGapSeconds=\(String(format: "%.0f", totalGapSeconds)) topGaps=[\(topGaps)]")
            }
        } catch {
            Log.error("[V2DIAG] coverage \(sessionUUID): fetch failed \(error)")
        }
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
