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
        Log.info("## Location tracker initialized")
        self.updateAuthorizationState() // redundant, cause did change authorization method get's called anyway
        Log.info("## Assigning delegate")
        self.locationManager.delegate = self
    }
    
    func start() {
        Log.info("## Tracker started: \(locationStartReference)")
        referenceLock.lock(); defer { referenceLock.unlock() }
        if locationStartReference == 0 {
            requestAuthorization()
            Log.info("## Starting updating locations")
            locationManager.startUpdatingLocation()
        }
        locationStartReference += 1
    }
    
    func stop() {
        Log.info("## Tracker stopped: \(locationStartReference)")
        referenceLock.lock(); defer { referenceLock.unlock() }
        locationStartReference -= 1
        if locationStartReference == 0 {
            Log.info("## Stopping updating locations")
            locationManager.stopUpdatingLocation()
            location.value = nil
        }
    }
    
//    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
//        referenceLock.lock(); defer { referenceLock.unlock() }
//        guard locationStartReference == 0 else {
//            Log.info("## locationStartReference wasn't 0: \(locationStartReference)")
//            completion(location.value)
//            return
//        }
//        oneTimeObservers.append(completion)
//        Log.info("## appended one time observer")
//        guard oneTimeObservers.count == 1 else { return }
//        Log.info("## requesting location")
//        locationManager.requestLocation()
//    }
    
    func requestAuthorization() {
        Log.info("## Requesting authorization")
        locationManager.requestAlwaysAuthorization()
    }
    
    private func updateAuthorizationState() {
        switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                Log.info("## Updating authorization: changing location state to granted")
                self.locationState = .granted
            case .denied, .notDetermined, .restricted:
                Log.info("## Updating authorization: changing location state to denied")
                self.locationState = .denied
            @unknown default:
                fatalError()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        location.value = latestLocation
//        oneTimeObservers.forEach { $0(latestLocation) }
        Log.info("## Did update locations.")
//        oneTimeObservers = []
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Log.info("## Location manager did change authorization")
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            Log.info("## Changing location state to granted")
            locationState = .granted
        case .denied, .notDetermined, .restricted:
            Log.info("## Changing location state to denied")
            locationState = .denied
        @unknown default:
            fatalError()
        }
    }
    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        Log.error("Location manager failed with error: \(error)")
//    }
}

//class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
//
//    let locationManager: CLLocationManager
//    @Published var locationGranted: LocationState
//
//    init(locationManager: CLLocationManager) {
//        self.locationManager = locationManager
//        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.allowsBackgroundLocationUpdates = true
//        locationManager.pausesLocationUpdatesAutomatically = false
//        switch locationManager.authorizationStatus {
//            case .authorizedAlways, .authorizedWhenInUse:
//                self.locationGranted = .granted
//            case .denied, .notDetermined, .restricted:
//                self.locationGranted = .denied
//            @unknown default:
//                fatalError()
//        }
//        super.init()
//        self.locationManager.delegate = self
//    }
//
//    func requestAuthorisation() {
//        locationManager.requestAlwaysAuthorization()
//    }
//
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        switch manager.authorizationStatus {
//        case .authorizedAlways, .authorizedWhenInUse:
//            locationGranted = .granted
//        case .denied, .notDetermined, .restricted:  locationGranted = .denied
//        @unknown default:
//            fatalError()
//        }
//    }
//}
