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
        Log.info("Started location tracking (refcount: \(locationStartReference))")
    }
    
    func stop() {
        referenceLock.lock(); defer { referenceLock.unlock() }
        locationStartReference -= 1
        if locationStartReference == 0 {
            locationManager.stopUpdatingLocation()
            location.value = nil
        }
        Log.info("Stopped location tracking (refcount: \(locationStartReference))")
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
        guard let latestLocation = locations.last else { return }
        location.value = latestLocation
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
    }
}

class UserTrackerAdapter: UserTracker {
    private let locationTracker: LocationTracker
    private var locationCancellable: AnyCancellable?
    
    init(_ locationTracker: LocationTracker) {
        self.locationTracker = locationTracker
    }
    
    func startTrackingUserPosision(_ newPos: @escaping (CLLocation) -> Void) {
        Log.verbose("## Starting tracking location")
        locationTracker.start()
        locationCancellable = locationTracker.location.sink {
            Log.verbose("## New location")
            newPos($0 ?? .applePark)
        }
    }
    
    deinit {
        Log.verbose("## Stopping tracking location")
        locationTracker.stop()
    }
}
