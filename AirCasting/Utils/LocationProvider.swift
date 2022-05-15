//
//  LocationProvider.swift
//  AirCasting
//
//  Created by Lunar on 15/03/2021.
//

import Foundation
import CoreLocation
import Combine

final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager
    @Published private(set) var currentLocation: CLLocation?

    init(locationManager: CLLocationManager = .init()) {
        self.locationManager = locationManager
        self.currentLocation = locationManager.location
    }

    func requestLocation()  {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        #warning("should startUpdatingLocation be called with requestWhenInUseAuthorization")
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}

extension LocationProvider: LocationService {
    func getCurrentLocation() throws -> CLLocationCoordinate2D? {
        currentLocation?.coordinate
    }
}
