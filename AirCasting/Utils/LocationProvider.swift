//
//  LocationProvider.swift
//  AirCasting
//
//  Created by Lunar on 15/03/2021.
//

import Foundation
import CoreLocation
import Combine

class LocationProvider: NSObject, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    
    func requestLocation()  {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}
