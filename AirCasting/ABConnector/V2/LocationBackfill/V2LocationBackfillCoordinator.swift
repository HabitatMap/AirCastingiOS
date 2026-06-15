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
}

final class DefaultV2LocationBackfillCoordinator: V2LocationBackfillCoordinator {
    @Injected private var store: LocationSampleStore
    @Injected private var locationTracker: LocationTracker
    private let lock = NSLock()
    private var samplers: [SessionUUID: V2LocationSampler] = [:]
    private var intervals: [SessionUUID: TimeInterval] = [:]

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
        lock.unlock()
        sampler?.stop()
        store.deleteAll(sessionUUID: sessionUUID)
        Log.info("V2LocationBackfill: stopped sampling \(sessionUUID)")
    }

    func location(for sessionUUID: SessionUUID, at timestamp: Date) -> CLLocationCoordinate2D? {
        lock.lock()
        let interval = intervals[sessionUUID] ?? 1.0
        lock.unlock()
        // Tolerance ≈ one interval. Symmetric window catches both
        // sample-before-measurement and sample-after-measurement cases.
        let tolerance = interval + 1.0
        guard let match = store.nearest(sessionUUID: sessionUUID,
                                        timestamp: timestamp,
                                        tolerance: tolerance) else {
            return nil
        }
        return match.coordinate
    }
}
