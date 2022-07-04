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
//    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void)
}

final class CoreLocationTracker: NSObject, LocationTracker, LocationAuthorization, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager
    // We want to accumulate all start/stop calls and only call stopUpdating
    // when no object really needs location. This is why we're using this counter
    private var locationStartReference: Int = 0
    private let referenceLock = NSRecursiveLock()
    // Stores all the observers that requested `getCurrentLocation`. There can
    // be multiple because of the fact that CLLocationManager's requestLocation
    // function can take several seconds to report back its results.
//    private var oneTimeObservers: [(CLLocation?) -> Void] = []
    private(set) var locationState: LocationState = .denied
    
    var location: CurrentValueSubject<CLLocation?, Never> = .init(nil)
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        super.init()
        self.updateAuthorizationState()
        self.locationManager.delegate = self
    }
    
    func start() {
        referenceLock.lock(); defer { referenceLock.unlock() }
        if locationStartReference == 0 {
            requestAuthorization()
            locationManager.startUpdatingLocation()
        }
        locationStartReference += 1
    }
    
    func stop() {
        referenceLock.lock(); defer { referenceLock.unlock() }
        locationStartReference -= 1
        if locationStartReference == 0 {
            locationManager.stopUpdatingLocation()
            location.value = nil
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
}
