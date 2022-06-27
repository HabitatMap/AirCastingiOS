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
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.locationGranted = .granted
            case .denied, .notDetermined, .restricted:
                self.locationGranted = .denied
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
