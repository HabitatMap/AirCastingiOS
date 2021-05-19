//
//  LocationTracker.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 26/01/2021.
//

import Foundation
import CoreLocation


class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private lazy var locationManager: CLLocationManager = {
        $0.desiredAccuracy = kCLLocationAccuracyBest
        $0.delegate = self
        return $0
    }(CLLocationManager())

    @Published var allLocations: [CLLocation] = []
    
    override init() {
        super.init()
        locationManager.requestAlwaysAuthorization()
        allLocations = locationManager.location.flatMap { [$0] } ?? []
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
