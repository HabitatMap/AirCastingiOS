// Created by Lunar on 17/11/2022.
//

import Foundation
import Resolver
import CoreLocation

protocol MeasurementsSavingService {
    func handlePeripheralMeasurement(_ measurement: ABMeasurementStream, sessionUUID: SessionUUID, locationless: Bool)
    func createSession(session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
    func changeStatusToRecording(for sessionUUID: SessionUUID)
    /// V2 path: save a single measurement with the device-provided timestamp.
    /// Bypasses the V1 batching path used for AB3/Mini-V1 (which generates a fake current time per N readings).
    func saveV2LiveMeasurement(_ measurement: ABMeasurementStream,
                               sessionUUID: SessionUUID,
                               time: Date,
                               locationless: Bool)
    /// V2 path: save a synced measurement using the device-stored timestamp.
    /// Firmware doesn't persist per-record GPS, so callers pass a
    /// `locationOverride` resolved via [[v2-location-backfill-coordinator]] (matched
    /// to the record timestamp against the phone-side sample buffer). When the
    /// override is nil (no buffered match), we fall back to the phone's last-known
    /// fix. Pass `locationless: true` to keep the row coordinate-free.
    func saveV2SyncMeasurement(_ measurement: ABMeasurementStream,
                               sessionUUID: SessionUUID,
                               time: Date,
                               locationless: Bool,
                               locationOverride: CLLocationCoordinate2D?)
    /// V2 path: batched chunk save. Resolves the PM1 + PM2.5 stream IDs once
    /// for the session and writes all paired records inside a single CoreData
    /// transaction. Used by `AirBeamMiniV2Configurator.persistSyncChunkLocked`
    /// and `persistManualSyncRecords` to avoid the per-record `updateStreams`
    /// storm that froze the UI during active-reconnect sync.
    /// `onPersisted` fires (on the storage queue) with the number of RECORDS
    /// actually committed once the CoreData write succeeds — distinct from the
    /// records merely handed off. Callers use it for confirmed-persist accounting
    /// so a silent persist failure can't masquerade as a successful save.
    func saveV2SyncBatch(_ records: [(pm1: ABMeasurementStream,
                                      pm25: ABMeasurementStream,
                                      time: Date,
                                      locationOverride: CLLocationCoordinate2D?)],
                         sessionUUID: SessionUUID,
                         locationless: Bool,
                         onPersisted: ((Int) -> Void)?)
    /// Drop any cached stream IDs for the session. Call on session stop /
    /// reconnect-reset so a re-created session doesn't reuse stale IDs.
    func clearV2SyncStreamCache(for sessionUUID: SessionUUID)
    /// Diagnostic: log the session's stored measurement coverage (counts,
    /// null-location rows, largest time gap) so a data gap can be classified
    /// from the shared log. Call at session finish, after any sync drain.
    func logMeasurementCoverage(for sessionUUID: SessionUUID)
}

extension MeasurementsSavingService {
    /// Back-compat convenience for callers that don't need confirmed-persist
    /// accounting (SD-card sync, manual finish-dialog sync).
    func saveV2SyncBatch(_ records: [(pm1: ABMeasurementStream,
                                      pm25: ABMeasurementStream,
                                      time: Date,
                                      locationOverride: CLLocationCoordinate2D?)],
                         sessionUUID: SessionUUID,
                         locationless: Bool) {
        saveV2SyncBatch(records, sessionUUID: sessionUUID, locationless: locationless, onPersisted: nil)
    }
}

class DefaultMeasurementsSaver: MeasurementsSavingService {
    @Injected private var persistence: MobileSessionRecordingStorage
    @Injected private var uiStorage: UIStorage
    private var peripheralMeasurementManager: PeripheralMeasurementTimeLocationManager?
    private var expectedMeasurementThreshold = 1

    /// Per-session cache of resolved PM1 + PM2.5 stream IDs. Populated lazily
    /// inside `saveV2SyncBatch` (on the storage context queue) and cleared by
    /// `clearV2SyncStreamCache`. Touched only from inside `accessStorage` so
    /// no extra locking is needed.
    private var v2SyncStreamCache: [SessionUUID: (pm1: MeasurementStreamLocalID,
                                                  pm25: MeasurementStreamLocalID)] = [:]

    /// Last LIVE measurement timestamp seen per session, used only to log a
    /// warning when the live stream skips a span (recording paused / BT
    /// disconnected and no measurement was saved). Surfaces start-of-session
    /// gaps — e.g. the ~35 min hole at session start in the 8-hr separated-device
    /// report — at the moment the stream resumes, which a buffer-side check
    /// cannot see (the hole was inside the live-saved region, before the device's
    /// SD buffer took over). Lock-protected: `saveV2LiveMeasurement` may be
    /// invoked off the storage queue.
    private var lastLiveMeasurementTS: [SessionUUID: TimeInterval] = [:]
    /// Last coordinate actually stamped on a LIVE measurement per session — the
    /// live-path carry-forward source. When the current fix is stale/absent we
    /// hold this (the previous live measurement's location) instead of storing
    /// nil, which the location-keyed export drops (producing the mid-session
    /// track holes while the phone sat stationary and CoreLocation throttled).
    /// Live measurements arrive in time order, so this IS "the measurement
    /// before them". In-memory is sufficient: live recording restarts with the
    /// app. Guarded by `lastLiveMeasurementLock`.
    private var lastKnownLiveLocationBySession: [SessionUUID: CLLocationCoordinate2D] = [:]
    private let lastLiveMeasurementLock = NSLock()
    /// Live gap above this (seconds) is logged. Sits above a few missed ~1 Hz
    /// samples so healthy sessions stay quiet; the reported holes were 75 s+.
    private static let liveMeasurementGapWarnSeconds: TimeInterval = 5

    class PeripheralMeasurementTimeLocationManager {
        @Injected private var locationTracker: LocationTracker

        private(set) var collectedMeasurementsCount: Int
        private(set) var currentTime: Date
        private(set) var currentLocation: CLLocationCoordinate2D?
        
        init(collectedMeasurementsCount: Int) {
            self.collectedMeasurementsCount = collectedMeasurementsCount
            self.currentTime = DateBuilder.getFakeUTCDate()
            self.currentLocation = .undefined
        }

        func startNewValuesRound(locationless: Bool) {
            currentLocation = !locationless ? locationTracker.location.value?.coordinate : .undefined
            currentTime = DateBuilder.getFakeUTCDate()
            collectedMeasurementsCount = 0
        }

        func incrementCounter() { collectedMeasurementsCount += 1 }
    }

    func createSession(session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        persistence.accessStorage { [weak self] storage in
            do {
                guard let self else { return }
                let sessionReturned = try storage.createSession(session)
                let entity = BluetoothConnectionEntity(context: sessionReturned.managedObjectContext!)
                entity.peripheralUUID = device.uuid
                entity.firmwareVersionRaw = Int16(device.firmwareVersion == .v2 ? 1 : 0)
                entity.session = sessionReturned
                self.uiStorage.accessStorage { storage in
                    do {
                        try storage.switchCardExpanded(to: true, sessionUUID: session.uuid)
                    } catch {
                        Log.error("\(error)")
                    }
                }
                setMeasurementThreshold(basedOn: device.airbeamType)
                peripheralMeasurementManager = .init(collectedMeasurementsCount: expectedMeasurementThreshold)
                completion(.success(()))
            } catch {
                Log.info("\(error)")
                completion(.failure(error))
            }
        }
    }
    
    private func setMeasurementThreshold(basedOn type: AirBeamDeviceType?) {
        /* Explanation: We anticipate receiving 5 measurements from AirBeam 3 and 2 from AirBeam Mini. It's crucial that these batches arrive with timestamps accurate to the second. Therefore, we wait for the expected number of measurements before updating streams with the current time. */
        switch type {
        case .airBeam3:
            expectedMeasurementThreshold = 5
        case .airBeamMini:
            expectedMeasurementThreshold = 2
        default:
            expectedMeasurementThreshold = 1
            Log.warning("There's an unknown device recording session")
        }
    }

    func handlePeripheralMeasurement(_ measurement: ABMeasurementStream, sessionUUID: SessionUUID, locationless: Bool) {
        guard let peripheralMeasurementManager else {
            Log.error("Peripheral Measurements Manager should have been initialized during session creation...")
            return
        }
        if peripheralMeasurementManager.collectedMeasurementsCount == expectedMeasurementThreshold {
            peripheralMeasurementManager.startNewValuesRound(locationless: locationless)
        }
        updateStreams(stream: measurement, sessionUUID: sessionUUID, location: peripheralMeasurementManager.currentLocation, time: peripheralMeasurementManager.currentTime)
        peripheralMeasurementManager.incrementCounter()
    }

    func changeStatusToRecording(for sessionUUID: SessionUUID) {
        persistence.accessStorage {
            do {
                try $0.updateSessionStatus(.RECORDING, for: sessionUUID)
            } catch {
                Log.error("Failed to change session status to recording")
            }
        }
    }

    func saveV2LiveMeasurement(_ measurement: ABMeasurementStream,
                               sessionUUID: SessionUUID,
                               time: Date,
                               locationless: Bool) {
        // Resolve LocationTracker lazily inside the call so DefaultMeasurementsSaver
        // (eagerly built at app boot via the BluetoothSessionRecordingController inject
        // chain) doesn't force CLLocationManager init during launch.
        logLiveMeasurementGapIfNeeded(sessionUUID: sessionUUID, time: time)
        let location: CLLocationCoordinate2D?
        if locationless {
            location = .undefined
        } else if let fresh = freshFixCoordinate(context: "LiveSave \(sessionUUID) stream=\(measurement.sensorName) ts=\(time.timeIntervalSince1970)") {
            location = fresh
            rememberLastKnownLiveLocation(fresh, for: sessionUUID)
        } else {
            // Stale or no fix: hold the last known live location (the previous
            // live measurement's coordinate) instead of nil — the live-path
            // analogue of the backfill carry-forward. Storing nil dropped the
            // measurement from the location-keyed export, producing the
            // mid-session track holes seen while the phone sat stationary and
            // CoreLocation throttled. nil only until the session's first fresh fix.
            location = lastKnownLiveLocationValue(for: sessionUUID)
            if location != nil {
                Log.info("V2Location.LiveCarryForward \(sessionUUID) ts=\(time.timeIntervalSince1970): stale/no fix → holding last-known live location")
            }
        }
        updateStreams(stream: measurement, sessionUUID: sessionUUID, location: location, time: time)
    }

    private func rememberLastKnownLiveLocation(_ coord: CLLocationCoordinate2D, for sessionUUID: SessionUUID) {
        lastLiveMeasurementLock.lock(); defer { lastLiveMeasurementLock.unlock() }
        lastKnownLiveLocationBySession[sessionUUID] = coord
    }

    private func lastKnownLiveLocationValue(for sessionUUID: SessionUUID) -> CLLocationCoordinate2D? {
        lastLiveMeasurementLock.lock(); defer { lastLiveMeasurementLock.unlock() }
        return lastKnownLiveLocationBySession[sessionUUID]
    }

    /// Logs a warning when the live measurement stream skips a span — i.e. no
    /// live measurement was saved between the previous one and this one for the
    /// session. PM1 + PM2.5 arrive as two calls at the same `time`, so the
    /// second is a no-op (gap 0). The high-water mark only ever advances.
    private func logLiveMeasurementGapIfNeeded(sessionUUID: SessionUUID, time: Date) {
        let ts = time.timeIntervalSince1970
        lastLiveMeasurementLock.lock(); defer { lastLiveMeasurementLock.unlock() }
        if let prev = lastLiveMeasurementTS[sessionUUID] {
            let gap = ts - prev
            if gap > Self.liveMeasurementGapWarnSeconds {
                Log.warning("V2Location.LiveGap \(sessionUUID): \(String(format: "%.0f", gap))s gap in LIVE measurements (prev ts=\(String(format: "%.0f", prev)) → now ts=\(String(format: "%.0f", ts))) — nothing saved for this span (recording paused / BT disconnected?)")
            }
        }
        if ts > (lastLiveMeasurementTS[sessionUUID] ?? 0) { lastLiveMeasurementTS[sessionUUID] = ts }
    }

    func saveV2SyncMeasurement(_ measurement: ABMeasurementStream,
                               sessionUUID: SessionUUID,
                               time: Date,
                               locationless: Bool,
                               locationOverride: CLLocationCoordinate2D?) {
        // Prefer the backfill-coordinator match (phone GPS captured at the record's
        // timestamp during the disconnect window). Fall back to the phone's last
        // known fix when no buffered match exists — preserves pre-backfill behavior
        // for cold-launch races, permission-denied gaps, and outside-tolerance
        // timestamps.
        let location: CLLocationCoordinate2D?
        let source: String
        if locationless {
            location = .undefined
            source = "locationless"
        } else if let locationOverride {
            location = locationOverride
            source = "backfill-override"
        } else {
            location = fallbackCoordinate(forRecordTime: time, context: "SyncFallback \(sessionUUID) stream=\(measurement.sensorName) ts=\(time.timeIntervalSince1970)")
            source = location == nil ? "fallback-dropped" : "fallback-current-fix"
        }
        Log.info("V2LocationBackfill.Save: \(sessionUUID) stream=\(measurement.sensorName) ts=\(time.timeIntervalSince1970) src=\(source) lat=\(location?.latitude.description ?? "nil") lon=\(location?.longitude.description ?? "nil")")
        updateStreams(stream: measurement, sessionUUID: sessionUUID, location: location, time: time)
    }

    func saveV2SyncBatch(_ records: [(pm1: ABMeasurementStream,
                                      pm25: ABMeasurementStream,
                                      time: Date,
                                      locationOverride: CLLocationCoordinate2D?)],
                         sessionUUID: SessionUUID,
                         locationless: Bool,
                         onPersisted: ((Int) -> Void)?) {
        guard !records.isEmpty else { return }
        // Resolve the fallback (phone last-known fix) once on the caller's
        // thread — pulling it inside `accessStorage` would hop to the
        // LocationTracker queue per chunk.
        let fallbackLocation: CLLocationCoordinate2D?
        if locationless {
            fallbackLocation = .undefined
        } else {
            fallbackLocation = freshFixCoordinate(context: "SyncBatchFallback \(sessionUUID) records=\(records.count)")
        }
        persistence.accessStorage { [weak self] storage in
            guard let self = self else { return }

            // One append attempt: (re)resolve the stream IDs and write all paired
            // records. `appendMeasurementValues` resolves streams before inserting
            // anything, so a stale-id throw leaves the batch atomic (no partial rows).
            func attempt() throws {
                let streamIDs = try self.resolveV2SyncStreamIDs(
                    sessionUUID: sessionUUID,
                    pm1Template: records[0].pm1,
                    pm25Template: records[0].pm25,
                    storage: storage
                )
                var entries: [(streamID: MeasurementStreamLocalID,
                               value: Double,
                               time: Date,
                               location: CLLocationCoordinate2D?)] = []
                entries.reserveCapacity(records.count * 2)
                // Compare each record's own timestamp against "now" (same
                // fake-UTC domain the device stamps records with) so we only
                // borrow the sync-time current fix for near-real-time records.
                let now = DateBuilder.getFakeUTCDate()
                var nOverride = 0, nFallbackUsed = 0, nFallbackDropped = 0, nLocationless = 0
                for record in records {
                    let location: CLLocationCoordinate2D?
                    if locationless {
                        location = .undefined
                        nLocationless += 1
                    } else if let override = record.locationOverride {
                        location = override
                        nOverride += 1
                    } else if let fb = fallbackLocation,
                              abs(now.timeIntervalSince(record.time)) <= Self.maxFallbackRecordAgeSeconds {
                        // Near-real-time reconnect gap: the current fix is a sane stand-in.
                        location = fb
                        nFallbackUsed += 1
                    } else {
                        // No sample match AND (no fresh fix OR this is a deferred/bulk
                        // sync of an old record). Borrowing the current fix here stamps
                        // an old measurement with where the phone is NOW — the km-scale
                        // "dot pops back". Store nil so the map holds instead.
                        location = nil
                        nFallbackDropped += 1
                    }
                    entries.append((streamIDs.pm1, record.pm1.measuredValue, record.time, location))
                    entries.append((streamIDs.pm25, record.pm25.measuredValue, record.time, location))
                }
                Log.info("V2LocationBackfill.BatchSrc: \(sessionUUID) records=\(records.count) override=\(nOverride) fallbackUsed=\(nFallbackUsed) fallbackDropped=\(nFallbackDropped) locationless=\(nLocationless)")
                try storage.appendMeasurementValues(entries)
            }

            do {
                try attempt()
                Log.info("[V2SYNC] SAVED batch: \(records.count) records (\(records.count * 2) measurements) for \(sessionUUID)")
                onPersisted?(records.count)
            } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == 133000 {
                // The cached stream objectID went stale — a temporary id invalidated
                // by a context refresh (the shared-editContext averaging save), or a
                // removed/old stream. This was the missing-middle data loss: every
                // later batch reused the dead id and was silently dropped. Self-heal:
                // drop the cache, re-resolve the stream fresh (now minted with a
                // permanent id), and retry the batch ONCE before giving up.
                Log.warning("[V2SYNC] save hit CoreData 133000 (stale stream id) for \(sessionUUID); clearing stream cache and retrying once (\(records.count) records).")
                self.v2SyncStreamCache.removeValue(forKey: sessionUUID)
                do {
                    try attempt()
                    Log.info("[V2SYNC] SAVED batch after retry: \(records.count) records (\(records.count * 2) measurements) for \(sessionUUID)")
                    onPersisted?(records.count)
                } catch {
                    Log.error("[V2SYNC] V2 sync batch save FAILED after retry — \(records.count) records LOST for \(sessionUUID): \(error)")
                }
            } catch {
                Log.error("[V2SYNC] V2 sync batch save failed — \(records.count) records LOST for \(sessionUUID): \(error)")
            }
        }
    }

    func clearV2SyncStreamCache(for sessionUUID: SessionUUID) {
        // Hop onto the storage queue so the cache mutation is serialized with
        // any in-flight `saveV2SyncBatch` access. `accessStorage` ignores its
        // task argument here aside from queue scheduling.
        persistence.accessStorage { [weak self] _ in
            self?.v2SyncStreamCache.removeValue(forKey: sessionUUID)
        }
        lastLiveMeasurementLock.lock()
        lastLiveMeasurementTS.removeValue(forKey: sessionUUID)
        lastKnownLiveLocationBySession.removeValue(forKey: sessionUUID)
        lastLiveMeasurementLock.unlock()
    }

    func logMeasurementCoverage(for sessionUUID: SessionUUID) {
        persistence.accessStorage { storage in
            storage.logMeasurementCoverage(sessionUUID: sessionUUID)
        }
    }

    private func resolveV2SyncStreamIDs(sessionUUID: SessionUUID,
                                        pm1Template: ABMeasurementStream,
                                        pm25Template: ABMeasurementStream,
                                        storage: HiddenMobileSessionRecordingStorage) throws -> (pm1: MeasurementStreamLocalID, pm25: MeasurementStreamLocalID) {
        if let cached = v2SyncStreamCache[sessionUUID] {
            return cached
        }
        let pm1ID: MeasurementStreamLocalID
        if let existing = try storage.existingMeasurementStream(sessionUUID, name: pm1Template.sensorName) {
            pm1ID = existing
        } else {
            pm1ID = try createSessionStream(pm1Template, sessionUUID, storage: storage)
        }
        let pm25ID: MeasurementStreamLocalID
        if let existing = try storage.existingMeasurementStream(sessionUUID, name: pm25Template.sensorName) {
            pm25ID = existing
        } else {
            pm25ID = try createSessionStream(pm25Template, sessionUUID, storage: storage)
        }
        let resolved = (pm1: pm1ID, pm25: pm25ID)
        v2SyncStreamCache[sessionUUID] = resolved
        return resolved
    }

    /// Maximum age a phone GPS fix may have before we refuse to stamp it onto
    /// a measurement. CoreLocation keeps the last fix in `location.value`
    /// indefinitely once it throttles delivery (stationary / backgrounded
    /// device), so a blind `location.value` read can peg a measurement to a
    /// fix that is minutes old and hundreds of metres away — the "blue dot
    /// pops back" bug. Above this age we store NO coordinate (nil) so the map
    /// holds the last good point instead of snapping, and nudge CoreLocation
    /// for a fresh fix. Tuned to sit well above normal ~1 Hz delivery yet
    /// below the observed stale-hold windows (20 s+). Mirrors the sampler's
    /// own stale-fix guard in [[v2-location-backfill]] (`V2LocationSampler`).
    private static let maxLiveFixAgeSeconds: TimeInterval = 10

    /// Resolve the phone's current fix coordinate, or nil when there is no fix
    /// or the cached fix has gone stale (see `maxLiveFixAgeSeconds`). Storing
    /// nil makes the map/graph skip the point (the dot holds at the last good
    /// location) rather than snapping to a stale coordinate. Logs the decision
    /// and fix age so a test session's logs reveal exactly which coordinate
    /// each measurement was stamped with and why.
    private func freshFixCoordinate(context: String) -> CLLocationCoordinate2D? {
        // Resolve lazily (not at init) so building this saver at app boot
        // doesn't force CLLocationManager creation — same rationale as the
        // other LocationTracker resolves on the save paths.
        let tracker = Resolver.resolve(LocationTracker.self)
        guard let fix = tracker.location.value else {
            Log.warning("V2Location.\(context): no fix available → store nil")
            return nil
        }
        let age = -fix.timestamp.timeIntervalSinceNow
        if age > Self.maxLiveFixAgeSeconds {
            Log.warning("V2Location.\(context): STALE fix age=\(String(format: "%.1f", age))s > \(Self.maxLiveFixAgeSeconds)s lat=\(fix.coordinate.latitude) lon=\(fix.coordinate.longitude) → store nil + nudge CoreLocation")
            tracker.requestOneShotUpdate()
            return nil
        }
        Log.info("V2Location.\(context): fresh fix age=\(String(format: "%.1f", age))s lat=\(fix.coordinate.latitude) lon=\(fix.coordinate.longitude)")
        return fix.coordinate
    }

    /// Max gap between a backfilled record's own timestamp and "now" for which
    /// we allow borrowing the phone's CURRENT fix as a fallback. The current
    /// fix is only a sane stand-in for a record taken ~now (a near-real-time
    /// reconnect gap). For DEFERRED / bulk sync — records minutes-to-hours old
    /// replayed long after the phone moved on — the current fix is FRESH BUT
    /// WRONG: it's where the phone is now, not where the record was taken.
    /// Stamping old records with it produced the kilometre-scale "dot pops
    /// back" seen in deferred-sync sessions (the staleness guard can't catch
    /// it — the fix isn't stale, it's the wrong record's location). Beyond this
    /// gap we store nil so the map holds at the last good point.
    private static let maxFallbackRecordAgeSeconds: TimeInterval = 30

    /// Backfill fallback coordinate for a single record: the current fix, but
    /// only when the record is recent enough that "now" ≈ the record's time
    /// (see `maxFallbackRecordAgeSeconds`). Otherwise nil.
    private func fallbackCoordinate(forRecordTime recordTime: Date, context: String) -> CLLocationCoordinate2D? {
        let recordAge = abs(DateBuilder.getFakeUTCDate().timeIntervalSince(recordTime))
        guard recordAge <= Self.maxFallbackRecordAgeSeconds else {
            Log.warning("V2Location.\(context): record \(String(format: "%.1f", recordAge))s old (> \(Self.maxFallbackRecordAgeSeconds)s) — deferred sync, current fix is wrong for this record → store nil")
            return nil
        }
        return freshFixCoordinate(context: context)
    }

    private func updateStreams(stream: ABMeasurementStream, sessionUUID: SessionUUID, location: CLLocationCoordinate2D?, time: Date) {
        persistence.accessStorage { storage in
            do {
                let existingStreamID = try storage.existingMeasurementStream(sessionUUID, name: stream.sensorName)
                guard let id = existingStreamID else {
                    let streamId = try self.createSessionStream(stream, sessionUUID, storage: storage)
                    try storage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: streamId, on: time)
                    return
                }
                try storage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: id, on: time)
            } catch {
                Log.error("Error saving value from peripheral: \(error)")
            }
        }
    }

    private func createSessionStream(_ stream: ABMeasurementStream, _ sessionUUID: SessionUUID, storage: HiddenMobileSessionRecordingStorage) throws -> MeasurementStreamLocalID {
        let sessionStream = MeasurementStream(id: nil,
                                              sensorName: stream.sensorName,
                                              sensorPackageName: stream.packageName,
                                              measurementType: stream.measurementType,
                                              measurementShortType: stream.measurementShortType,
                                              unitName: stream.unitName,
                                              unitSymbol: stream.unitSymbol,
                                              thresholdVeryHigh: Int32(stream.thresholdVeryHigh),
                                              thresholdHigh: Int32(stream.thresholdHigh),
                                              thresholdMedium: Int32(stream.thresholdMedium),
                                              thresholdLow: Int32(stream.thresholdLow),
                                              thresholdVeryLow: Int32(stream.thresholdVeryLow))

        return try storage.saveMeasurementStream(sessionStream, for: sessionUUID)
    }
}
