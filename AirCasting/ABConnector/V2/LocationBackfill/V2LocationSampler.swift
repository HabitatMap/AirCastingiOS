// V2 disconnect-window location backfill.
//
// Per-session sampler — subscribes to `LocationTracker.location` and writes a
// LocationSample to the store at most once per measurement interval. Sampling
// runs for the lifetime of the session (not gated on disconnect) so that the
// store always has coverage when sync replays measurements from the device.

import Foundation
import Combine
import CoreLocation
import Resolver

final class V2LocationSampler {
    private let sessionUUID: SessionUUID
    private let intervalSeconds: TimeInterval
    private let store: LocationSampleStore
    private let locationTracker: LocationTracker
    private var cancellable: AnyCancellable?
    private var lastSampledAt: Date?

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
        guard cancellable == nil else { return }
        cancellable = locationTracker.location
            .sink { [weak self] location in
                self?.handle(location)
            }
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
    }

    private func handle(_ location: CLLocation?) {
        guard let location else { return }
        let now = Date()
        if let last = lastSampledAt, now.timeIntervalSince(last) < intervalSeconds {
            return
        }
        lastSampledAt = now
        let sample = LocationSample(
            sessionUUID: sessionUUID,
            timestamp: now,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        store.insert(sample)
    }
}
