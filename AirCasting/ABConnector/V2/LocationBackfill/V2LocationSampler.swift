// V2 disconnect-window location backfill.
//
// Per-session sampler — snapshots `LocationTracker.location.value` on a timer
// at the session measurement interval. Timer-driven (rather than purely
// publisher-driven) so we still get a sample on every tick even when
// CLLocationManager has not emitted a new `didUpdateLocations` (common with
// stationary devices or Xcode debug-location toggles). Sampling runs for the
// lifetime of the session so the store always has coverage when sync replays
// measurements from the device.
//
// In long, backgrounded mobile sessions CoreLocation aggressively throttles
// delivery on a stationary phone, so `location.value` can be stale for
// minutes at a time. Every timer tick checks the fix age and asks for a
// fresh one-shot update when the cached fix has gone stale. Stale and
// low-accuracy fixes are dropped before they reach the store to keep the
// nearest() lookup from snapping every disconnect-window measurement to
// the same coordinate.

import Foundation
import Combine
import CoreLocation
import Resolver

final class V2LocationSampler {
    /// Skip persisting a CL fix whose `horizontalAccuracy` is worse than
    /// this (or negative — CoreLocation uses negative to mean "invalid").
    /// Tuned for outdoor mobile sessions; raise if needed for dense urban
    /// canyons or indoor sessions, where CL routinely reports 30–80 m.
    static let maxAcceptableHorizontalAccuracyMeters: CLLocationAccuracy = 100

    private let sessionUUID: SessionUUID
    private let intervalSeconds: TimeInterval
    private let store: LocationSampleStore
    private let locationTracker: LocationTracker
    private var timer: DispatchSourceTimer?
    private var publisherCancellable: AnyCancellable?
    private let queue = DispatchQueue(label: "v2.location.sampler", qos: .utility)

    init(sessionUUID: SessionUUID,
         intervalSeconds: TimeInterval,
         store: LocationSampleStore,
         locationTracker: LocationTracker) {
        self.sessionUUID = sessionUUID
        self.intervalSeconds = max(1.0, intervalSeconds)
        self.store = store
        self.locationTracker = locationTracker
    }

    func start() {
        let uuidStr = self.sessionUUID.rawValue
        let interval = self.intervalSeconds
        guard timer == nil else {
            Log.info("V2LocationBackfill.Sampler[\(uuidStr)]: start() ignored — already running")
            return
        }
        Log.info("V2LocationBackfill.Sampler[\(uuidStr)]: start interval=\(interval)s")
        // Capture the first fix the instant CLLocationManager reports it
        // (don't wait up to a full interval for the first timer tick).
        publisherCancellable = locationTracker.location
            .compactMap { $0 }
            .first()
            .sink { [weak self] location in
                self?.persist(location: location, source: "first-publisher-emit")
            }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(200))
        t.setEventHandler { [weak self] in
            self?.tick()
        }
        timer = t
        t.resume()
    }

    func stop() {
        let uuidStr = self.sessionUUID.rawValue
        if timer != nil {
            Log.info("V2LocationBackfill.Sampler[\(uuidStr)]: stop")
        }
        timer?.cancel()
        timer = nil
        publisherCancellable?.cancel()
        publisherCancellable = nil
    }

    private func tick() {
        let uuidStr = self.sessionUUID.rawValue
        let interval = self.intervalSeconds
        guard let location = locationTracker.location.value else {
            Log.info("V2LocationBackfill.Sampler[\(uuidStr)]: tick — no current location yet, skipping")
            return
        }
        // Stale-fix drop + nudge: CoreLocation may have throttled delivery
        // while the app is backgrounded. If the cached fix's `timestamp` is
        // older than 2 × the session interval, ask for a fresh one AND drop
        // this tick. `persist()` stamps the sample with the current
        // fake-UTC wall clock, not the fix's own timestamp — so persisting a
        // stale fix would file an OLD coordinate under a FRESH timestamp.
        // `nearest()` then matches that poisoned sample to disconnect-window
        // records and snaps them all to one stale coordinate (typically the
        // first fix of a stationary session), making the map dot pop back to
        // the start. The fresh fix from the nudge flows through
        // `didUpdateLocations` → `location.value` and is picked up by a later
        // tick. Missing a few samples here is harmless: the backfill lookup
        // falls through to the sync-time current fix when no sample matches.
        let fixAge = -location.timestamp.timeIntervalSinceNow
        if fixAge > interval * 2 {
            Log.info("V2LocationBackfill.Sampler[\(uuidStr)]: tick — fix age \(String(format: "%.1f", fixAge))s > \(interval * 2)s, nudging CoreLocation and dropping stale fix")
            locationTracker.requestOneShotUpdate()
            return
        }
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= Self.maxAcceptableHorizontalAccuracyMeters else {
            Log.info("V2LocationBackfill.Sampler[\(uuidStr)]: tick — dropping fix accuracy=\(location.horizontalAccuracy)m age=\(String(format: "%.1f", fixAge))s")
            return
        }
        persist(location: location, source: "timer-tick", fixAge: fixAge)
    }

    private func persist(location: CLLocation, source: String, fixAge: TimeInterval? = nil) {
        let uuidStr = self.sessionUUID.rawValue
        // Use the same "fake-UTC" wall-clock domain that the V2 device stamps
        // its records with (via `buildSetTime` → `getFakeUTCDate`). Phone `Date()`
        // would be TZ-offset hours away from `V2SyncRecord.timestamp` and every
        // lookup would miss.
        let now = DateBuilder.getFakeUTCDate()
        let sample = LocationSample(
            sessionUUID: sessionUUID,
            timestamp: now,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        let ageString = fixAge.map { String(format: "%.1f", $0) } ?? "n/a"
        Log.info("V2LocationBackfill.Sampler[\(uuidStr)]: persist (\(source)) ts=\(now.timeIntervalSince1970) lat=\(location.coordinate.latitude) lon=\(location.coordinate.longitude) acc=\(location.horizontalAccuracy)m age=\(ageString)s")
        store.insert(sample)
    }
}
