//
//  LocationTracker.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 26/01/2021.
//

import Foundation
import CoreLocation


class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()

    @Published var allLocations: [CLLocation] = []
    
    override init() {
        super.init()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.delegate = self
        //self.locationManager.startUpdatingLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            #warning("TODO: Handle denied state.")
        case .denied: break
        case .notDetermined: break
        case .restricted: break
        @unknown default:
            fatalError()
        }
    }
        
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        allLocations.append(contentsOf: locations)
    }
}
