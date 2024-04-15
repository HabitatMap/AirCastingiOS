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
            locationManager.startUpdatingLocation()
        }
        locationStartReference += 1
        Log.info("Started location tracking (refcount: \(self.locationStartReference))")
        assert(locationStartReference >= 0)
    }
    
    func stop() {
        referenceLock.lock(); defer { referenceLock.unlock() }
        locationStartReference -= 1
        if locationStartReference == 0 {
            locationManager.stopUpdatingLocation()
            location.value = nil
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
            if didCheckForOneTimeUpdate {
                finishLocationUpdate(with: .success(latestLocation))
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationState = .granted
        case .denied, .notDetermined, .restricted:
            locationState = .denied
        @unknown default:
            fatalError()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.warning("Location fetch failed with error: \(error.localizedDescription)")
        if didCheckForOneTimeUpdate {
            finishLocationUpdate(with: .failure(error))
        }
    }
    
    private func finishLocationUpdate(with result: Result<CLLocation, Error>) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(with: result)
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
