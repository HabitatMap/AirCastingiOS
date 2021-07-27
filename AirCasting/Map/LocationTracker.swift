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
    
    init(locationManager: CLLocationManager, locationGranted: LocationState, allLocations: [CLLocation]) {
        self.locationManager = locationManager
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.delegate = (locationManager as! CLLocationManagerDelegate)
        switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse: self.locationGranted = .granted
            case .denied:  self.locationGranted = .denied
            case .notDetermined: self.locationGranted = .denied
            case .restricted: self.locationGranted = .denied
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
        case .denied:  locationGranted = .denied
        case .notDetermined: locationGranted = .denied
        case .restricted: locationGranted = .denied
        @unknown default:
            fatalError()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        allLocations.append(contentsOf: locations)
    }
}
