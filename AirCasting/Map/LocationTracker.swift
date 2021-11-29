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
    @Published var googleLocation: [PathPoint]
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        #warning("TESTING PURPOUSE: shorturl.at/ilwS1")
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        // End of TESTING PURPOUSE
        switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.locationGranted = .granted
                if locationManager.location?.coordinate.latitude != nil && locationManager.location?.coordinate.longitude != nil {
                    googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!,
                                                                                 longitude: (locationManager.location?.coordinate.longitude)!),
                                                measurementTime: Date(),
                                                measurement: 20)]
                } else {
                    googleLocation = [PathPoint.fakePathPoint]
                }
            case .denied, .notDetermined, .restricted:
                self.locationGranted = .denied
                googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: 37.35, longitude: -122.05), measurementTime: Date().currentUTCTimeZoneDate, measurement: 20.0)]
                #warning("Do something with hard coded measurement")
            @unknown default:
                fatalError()
        }
        super.init()
        self.locationManager.delegate = self
    }
    
    func requestAuthorisation() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationGranted = .granted
        case .denied, .notDetermined, .restricted:  locationGranted = .denied
        @unknown default:
            fatalError()
        }
    }
}

#if DEBUG
class DummyLocationTrakcer: LocationTracker {
    init() {
        super.init(locationManager: CLLocationManager())
    }
}
#endif
