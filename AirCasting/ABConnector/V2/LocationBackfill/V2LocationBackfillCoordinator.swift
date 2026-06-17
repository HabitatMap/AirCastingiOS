// V2 disconnect-window location backfill.
//
// Public facade for the backfill module. External code only touches this
// coordinator (start/stop on the session lifecycle, lookup at sync save time)
// so that the module can evolve independently with minimal surface area.

import Foundation
import CoreLocation
import Resolver

protocol V2LocationBackfillCoordinator {
    func startSampling(sessionUUID: SessionUUID, intervalSeconds: TimeInterval)
    func stopSampling(sessionUUID: SessionUUID)
    func location(for sessionUUID: SessionUUID, at timestamp: Date) -> CLLocationCoordinate2D?
    /// Mark a sync save batch as in flight. Pair with `endSaveBatch`.
    /// While at least one batch is open for a session, a concurrent
    /// `stopSampling` will not wipe the sample buffer — the wipe is
    /// deferred until the matching `endSaveBatch` brings the count to 0.
    func beginSaveBatch(sessionUUID: SessionUUID)
    func endSaveBatch(sessionUUID: SessionUUID)
}

final class DefaultV2LocationBackfillCoordinator: V2LocationBackfillCoordinator {
    @Injected private var store: LocationSampleStore
    @Injected private var locationTracker: LocationTracker
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

    func location(for sessionUUID: SessionUUID, at timestamp: Date) -> CLLocationCoordinate2D? {
        lock.lock()
        let interval = intervals[sessionUUID] ?? 1.0
        let hasSampler = samplers[sessionUUID] != nil
        lock.unlock()
        // Tolerance ≈ one interval. Symmetric window catches both
        // sample-before-measurement and sample-after-measurement cases.
        let tolerance = interval + 1.0
        Log.info("V2LocationBackfill.Coord: lookup \(sessionUUID) target=\(timestamp.timeIntervalSince1970) interval=\(interval)s tol=\(tolerance)s hasActiveSampler=\(hasSampler)")
        guard let match = store.nearest(sessionUUID: sessionUUID,
                                        timestamp: timestamp,
                                        tolerance: tolerance) else {
            return nil
        }
        return match.coordinate
    }
}
