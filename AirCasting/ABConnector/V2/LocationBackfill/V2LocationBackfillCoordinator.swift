// V2 disconnect-window location backfill.
//
// Public facade for the backfill module. External code only touches this
// coordinator (start/stop on the session lifecycle, lookup at sync save time)
// so that the module can evolve independently with minimal surface area.

import Foundation
import CoreData
import CoreLocation
import Resolver

protocol V2LocationBackfillCoordinator {
    func startSampling(sessionUUID: SessionUUID, intervalSeconds: TimeInterval)
    func stopSampling(sessionUUID: SessionUUID)
    func location(for sessionUUID: SessionUUID, at timestamp: Date) -> CLLocationCoordinate2D?
    /// Batched form of `location(for:at:)` — returns one coordinate per
    /// input timestamp, in the same order. Backed by a single CoreData
    /// fetch plus a two-pointer sweep so the cost is O(N + M) rather than
    /// N per-record fetches.
    func locations(for sessionUUID: SessionUUID, at timestamps: [Date]) -> [CLLocationCoordinate2D?]
    /// Mark a sync save batch as in flight. Pair with `endSaveBatch`.
    /// While at least one batch is open for a session, a concurrent
    /// `stopSampling` will not wipe the sample buffer — the wipe is
    /// deferred until the matching `endSaveBatch` brings the count to 0.
    func beginSaveBatch(sessionUUID: SessionUUID)
    func endSaveBatch(sessionUUID: SessionUUID)
    /// Cold-launch hook: scan persisted V2 mobile sessions that are still
    /// in `RECORDING` or `DISCONNECTED` and restart samplers for them.
    /// Without this, an app kill mid-session leaves the disconnect window
    /// unsampled until BLE reconnect — which may never happen in the
    /// "Finish & sync" flow.
    func bootstrap()
}

final class DefaultV2LocationBackfillCoordinator: V2LocationBackfillCoordinator {
    @Injected private var store: LocationSampleStore
    @Injected private var locationTracker: LocationTracker
    @Injected private var persistenceController: PersistenceController
    private let lock = NSLock()
    private var samplers: [SessionUUID: V2LocationSampler] = [:]
    private var intervals: [SessionUUID: TimeInterval] = [:]
    /// Per-session count of save batches currently in flight (between
    /// `beginSaveBatch` and `endSaveBatch`).
    private var inflightBatches: [SessionUUID: Int] = [:]
    /// Sessions for which `stopSampling` has been called while save batches
    /// were still in flight. The actual sample wipe is deferred until the
    /// last matching `endSaveBatch` drains the counter.
    private var pendingDeletion: Set<SessionUUID> = []

    func startSampling(sessionUUID: SessionUUID, intervalSeconds: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        guard samplers[sessionUUID] == nil else { return }
        let interval = max(1.0, intervalSeconds)
        let sampler = V2LocationSampler(
            sessionUUID: sessionUUID,
            intervalSeconds: interval,
            store: store,
            locationTracker: locationTracker
        )
        sampler.start()
        samplers[sessionUUID] = sampler
        intervals[sessionUUID] = interval
        Log.info("V2LocationBackfill: started sampling \(sessionUUID) @ \(interval)s")
    }

    func stopSampling(sessionUUID: SessionUUID) {
        lock.lock()
        let sampler = samplers.removeValue(forKey: sessionUUID)
        intervals.removeValue(forKey: sessionUUID)
        let inflight = inflightBatches[sessionUUID] ?? 0
        let shouldDeleteNow = inflight == 0
        if !shouldDeleteNow {
            pendingDeletion.insert(sessionUUID)
        }
        lock.unlock()
        sampler?.stop()
        if shouldDeleteNow {
            store.deleteAll(sessionUUID: sessionUUID)
            Log.info("V2LocationBackfill: stopped sampling \(sessionUUID) — no inflight batches, deleted immediately")
        } else {
            Log.info("V2LocationBackfill: stopped sampling \(sessionUUID) — \(inflight) inflight batch(es), delete deferred until drain")
        }
    }

    func beginSaveBatch(sessionUUID: SessionUUID) {
        lock.lock()
        let next = (inflightBatches[sessionUUID] ?? 0) + 1
        inflightBatches[sessionUUID] = next
        lock.unlock()
        Log.info("V2LocationBackfill: beginSaveBatch \(sessionUUID) inflight=\(next)")
    }

    func endSaveBatch(sessionUUID: SessionUUID) {
        lock.lock()
        let remaining = (inflightBatches[sessionUUID] ?? 1) - 1
        if remaining <= 0 {
            inflightBatches.removeValue(forKey: sessionUUID)
        } else {
            inflightBatches[sessionUUID] = remaining
        }
        let drain = remaining <= 0 && pendingDeletion.contains(sessionUUID)
        if drain { pendingDeletion.remove(sessionUUID) }
        lock.unlock()
        Log.info("V2LocationBackfill: endSaveBatch \(sessionUUID) inflight=\(max(0, remaining)) drainNow=\(drain)")
        if drain {
            store.deleteAll(sessionUUID: sessionUUID)
        }
    }

    func bootstrap() {
        let ctx = persistenceController.editContext
        var resumed: [(SessionUUID, TimeInterval)] = []
        var activeUUIDs: Set<SessionUUID> = []
        ctx.performAndWait {
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "type == %@ AND status IN %@ AND locationless == NO",
                SessionType.mobile.rawValue,
                [SessionStatus.RECORDING, .DISCONNECTED].map(\.rawValue)
            )
            let rows: [SessionEntity]
            do {
                rows = try ctx.fetch(request)
            } catch {
                Log.error("V2LocationBackfill.bootstrap: fetch failed: \(error)")
                return
            }
            for session in rows {
                // V2-only — V1 sessions don't go through this backfill path.
                // The reconnection controller's V1 branch streams new
                // measurements live with the current fix and doesn't
                // replay from a device-side buffer.
                guard session.deviceFirmwareVersion == .v2 else { continue }
                let interval = TimeInterval(session.nativeMeasurementIntervalSeconds)
                resumed.append((session.uuid, interval))
                activeUUIDs.insert(session.uuid)
            }
        }
        for (uuid, interval) in resumed {
            startSampling(sessionUUID: uuid, intervalSeconds: interval)
        }
        Log.info("V2LocationBackfill.bootstrap: resumed \(resumed.count) sampler(s) — \(resumed.map { $0.0.rawValue })")
        store.deleteOrphans(activeSessionUUIDs: activeUUIDs)
    }

    func location(for sessionUUID: SessionUUID, at timestamp: Date) -> CLLocationCoordinate2D? {
        let (interval, hasSampler) = lookupContext(for: sessionUUID)
        let tolerance = interval + 1.0
        Log.info("V2LocationBackfill.Coord: lookup \(sessionUUID) target=\(timestamp.timeIntervalSince1970) interval=\(interval)s tol=\(tolerance)s hasActiveSampler=\(hasSampler)")
        guard let match = store.nearest(sessionUUID: sessionUUID,
                                        timestamp: timestamp,
                                        tolerance: tolerance) else {
            return nil
        }
        return match.coordinate
    }

    func locations(for sessionUUID: SessionUUID, at timestamps: [Date]) -> [CLLocationCoordinate2D?] {
        guard !timestamps.isEmpty else { return [] }
        let (interval, hasSampler) = lookupContext(for: sessionUUID)
        let tolerance = interval + 1.0
        Log.info("V2LocationBackfill.Coord: batchLookup \(sessionUUID) n=\(timestamps.count) interval=\(interval)s tol=\(tolerance)s hasActiveSampler=\(hasSampler)")
        return store
            .nearestBatch(sessionUUID: sessionUUID, timestamps: timestamps, tolerance: tolerance)
            .map { $0?.coordinate }
    }

    private func lookupContext(for sessionUUID: SessionUUID) -> (TimeInterval, Bool) {
        lock.lock()
        let interval = intervals[sessionUUID] ?? 1.0
        let hasSampler = samplers[sessionUUID] != nil
        lock.unlock()
        return (interval, hasSampler)
    }
}
