//
//  LocationTracker.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 26/01/2021.
//

import Foundation
import CoreLocation

import Combine

protocol LocationAuthorization {
    var locationState: LocationState { get }
    func requestAuthorization()
}

protocol LocationTracker {
    func start()
    func stop()
    func oneTimeLocationUpdate() async throws -> CLLocation
    /// Ask CoreLocation for a single fresh fix without disturbing the
    /// existing continuous-updates subscription. Used by the V2
    /// disconnect-window sampler to nudge CoreLocation when
    /// `location.value` has gone stale (typical for long-backgrounded
    /// sessions where the OS throttles delivery on a stationary device).
    func requestOneShotUpdate()
    var location: CurrentValueSubject<CLLocation?, Never> { get }
}

final class CoreLocationTracker: NSObject, LocationTracker, LocationAuthorization, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager
    // We want to accumulate all start/stop calls and only call stopUpdating
    // when no object really needs location. This is why we're using this counter
    private var locationStartReference: Int = 0
    private let referenceLock = NSRecursiveLock()
    private(set) var locationState: LocationState = .denied {
        didSet {
            guard locationState != oldValue, locationState == .granted else { return }
            self.locationManager.requestLocation()
        }
    }
    
    private var didCheckForOneTimeUpdate = false
    private var locationCancellable: AnyCancellable?
    var oneTimeLocationTracker: CurrentValueSubject<Void, Never> = .init(())
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    var location: CurrentValueSubject<CLLocation?, Never> = .init(nil)

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
        self.updateAuthorizationState()
    }
    
    func start() {
        referenceLock.lock(); defer { referenceLock.unlock() }
        if locationStartReference == 0 {
            requestAuthorization()
            // Re-assert background delivery on every fresh start. The
            // manager is configured once at injection time, but defensive
            // re-assertion guards against any future code path that
            // toggles either flag and forgets to restore them — a single
            // missed re-set is enough to mute background samples on a
            // 2 h+ session.
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.startUpdatingLocation()
        }
        locationStartReference += 1
        Log.info("Started location tracking (refcount: \(self.locationStartReference))")
        assert(locationStartReference >= 0)
    }

    func requestOneShotUpdate() {
        // Cheap nudge: CoreLocation queues this against the same delegate;
        // the new fix (when delivered) flows through `didUpdateLocations`
        // and pops out via `location.value` like any other update. No
        // continuation is involved (see `oneTimeLocationUpdate(...)` for
        // the awaitable variant).
        locationManager.requestLocation()
    }
    
    func stop() {
        referenceLock.lock(); defer { referenceLock.unlock() }
        locationStartReference -= 1
        if locationStartReference == 0 {
            locationManager.stopUpdatingLocation()
            // Keep last-known location in `location.value` across stop/start cycles.
            // Mobile-session reconnect briefly drops refcount to 0 when SwiftUI
            // re-evaluates the session card body across the DISCONNECTED status flip,
            // and the V2 measurement-save path falls back to `.undefined` (200,200)
            // whenever `location.value == nil`. Retaining the last fix mirrors
            // Android's fused-location behavior — CoreLocation overwrites it on the
            // next real update once tracking resumes.
        }
        Log.info("Stopped location tracking (refcount: \(self.locationStartReference))")
        assert(locationStartReference >= 0)
    }
    
    func oneTimeLocationUpdate() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.locationContinuation = continuation
            self?.didCheckForOneTimeUpdate = true
            self?.locationManager.requestLocation()
        }
    }
    
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    private func updateAuthorizationState() {
        switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.locationState = .granted
            case .denied, .notDetermined, .restricted:
                self.locationState = .denied
            @unknown default:
                fatalError()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let latestLocation = locations.last {
            location.value = latestLocation
            checkForOneTimeLocationUpdate(with: .success(latestLocation))
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationState = .granted
            locationManager.startUpdatingLocation()
        case .denied, .notDetermined, .restricted:
            locationState = .denied
        @unknown default:
            fatalError()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.warning("Location fetch failed with error: \(error.localizedDescription)")
        checkForOneTimeLocationUpdate(with: .failure(error))
    }
    
    private func finishLocationUpdate(with result: Result<CLLocation, Error>) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(with: result)
    }
    
    private func checkForOneTimeLocationUpdate(with result: Result<CLLocation, Error>) {
        if didCheckForOneTimeUpdate {
            finishLocationUpdate(with: result)
            didCheckForOneTimeUpdate = false
        }
    }
}

class MapLocationTrackerAdapter: MapLocationTracker {
    private let locationTracker: LocationTracker
    private var locationCancellable: AnyCancellable?
    private var didStartTracking: Bool = false
    
    init(_ locationTracker: LocationTracker) {
        self.locationTracker = locationTracker
    }
    
    func startTrackingUserPosition(_ newPos: @escaping (CLLocation) -> Void) -> MapLocationTrackerStoper {
        locationTracker.start()
        didStartTracking = true
        locationCancellable = locationTracker.location.sink {
            newPos($0 ?? .applePark)
        }
        return Stoper(locationTracker: locationTracker)
    }
    
    func getLastKnownLocation() -> CLLocation? {
        locationTracker.location.value
    }
    
    deinit {
        guard didStartTracking else { return }
        locationTracker.stop()
    }
    
    private struct Stoper: MapLocationTrackerStoper {
        
        let locationTracker: LocationTracker
        
        func stopTrackingUserPosition() {
            locationTracker.stop()
        }
    }
}

struct ConstantTracker: MapLocationTracker {
    let location: CLLocation
    
    func getLastKnownLocation() -> CLLocation? {
        location
    }
    
    func startTrackingUserPosition(_ newPos: @escaping (CLLocation) -> Void) -> MapLocationTrackerStoper {
        newPos(location)
        return Stoper()
    }
    
    func stopTrackingUserPosition() {
        // nothing - that's ok
    }
    
    private struct Stoper: MapLocationTrackerStoper {
        func stopTrackingUserPosition() {
            
        }
    }
}
