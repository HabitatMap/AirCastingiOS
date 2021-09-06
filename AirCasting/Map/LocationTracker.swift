//
//  LocationTracker.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 26/01/2021.
//

import Foundation
import CoreLocation

class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    let locationManager: CLLocationManager
    @Published var locationGranted: LocationState
    @Published var allLocations: [CLLocation]
    @Published var googleLocation: [PathPoint]
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.locationGranted = .granted
                if locationManager.location?.coordinate.latitude != nil && locationManager.location?.coordinate.longitude != nil {
                    googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!), measurementTime: Date(), measurement: 20)]
                } else {
                    googleLocation = [PathPoint.fakePathPoint]
                }
            case .denied, .notDetermined, .restricted:
                self.locationGranted = .denied
                googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: 37.35, longitude: -122.05), measurementTime: Date(), measurement: 20.0)]
                #warning("Do something with hard coded measurement")
            @unknown default:
                fatalError()
        }
        self.allLocations = []
        super.init()
        self.locationManager.delegate = self
    }
    
    func requestAuthorisation() {
        locationManager.requestAlwaysAuthorization()
        allLocations = locationManager.location.flatMap { [$0] } ?? []
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            locationGranted = .granted
        case .denied, .notDetermined, .restricted:  locationGranted = .denied
        @unknown default:
            fatalError()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        allLocations.append(contentsOf: locations)
    }
}

#if DEBUG
class DummyLocationTrakcer: LocationTracker {
    init() {
        super.init(locationManager: CLLocationManager())
    }
}
#endif
