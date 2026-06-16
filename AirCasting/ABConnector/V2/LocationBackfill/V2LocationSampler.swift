// V2 disconnect-window location backfill.
//
// Per-session sampler — snapshots `LocationTracker.location.value` on a timer
// at the session measurement interval. Timer-driven (rather than purely
// publisher-driven) so we still get a sample on every tick even when
// CLLocationManager has not emitted a new `didUpdateLocations` (common with
// stationary devices or Xcode debug-location toggles). Sampling runs for the
// lifetime of the session so the store always has coverage when sync replays
// measurements from the device.

import Foundation
import Combine
import CoreLocation
import Resolver

final class V2LocationSampler {
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
        guard let location = locationTracker.location.value else {
            Log.info("V2LocationBackfill.Sampler[\(uuidStr)]: tick — no current location yet, skipping")
            return
        }
        persist(location: location, source: "timer-tick")
    }

    private func persist(location: CLLocation, source: String) {
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
        Log.info("V2LocationBackfill.Sampler[\(uuidStr)]: persist (\(source)) ts=\(now.timeIntervalSince1970) lat=\(location.coordinate.latitude) lon=\(location.coordinate.longitude)")
        store.insert(sample)
    }
}
