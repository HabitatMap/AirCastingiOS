//
//  SessionContext.swift
//  AirCasting
//
//  Created by Lunar on 10/03/2021.
//

import Foundation
import CoreBluetooth
import CoreData
import AVFoundation
import CoreLocation

final class CreateSessionContext: ObservableObject {
    var sessionName: String?
    var sessionTags: String?
    var sessionUUID: SessionUUID?
    var sessionType: SessionType?
    var peripheral: CBPeripheral?
    var wifiSSID: String?
    var wifiPassword: String?
    var isIndoor: Bool?
    var startingLocation: CLLocationCoordinate2D?
    var deviceType: DeviceType?
    var contribute: Bool?

    private var syncSink: Any?
    
    private var locationProvider: LocationProvider?
    private var locationSink: Any?
    
    func obtainCurrentLocation(lat: Double, log: Double) {
        locationProvider = LocationProvider()
        locationProvider?.requestLocation()
        startingLocation = CLLocationCoordinate2D(latitude: lat, longitude: log)
    }
}
