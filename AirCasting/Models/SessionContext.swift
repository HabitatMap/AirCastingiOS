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
    var locationless: Bool = false

    private var syncSink: Any?
    
    private var locationSink: Any?
    
    func ovverride(sessionContext: CreateSessionContext) {
        sessionName = sessionContext.sessionName
        sessionTags = sessionContext.sessionTags
        sessionUUID = sessionContext.sessionUUID
        sessionType = sessionContext.sessionType
        peripheral = sessionContext.peripheral
        wifiSSID = sessionContext.wifiSSID
        wifiPassword = sessionContext.wifiPassword
        isIndoor = sessionContext.isIndoor
        startingLocation = sessionContext.startingLocation
        deviceType = sessionContext.deviceType
        contribute = sessionContext.contribute
        locationless = sessionContext.locationless
    }
    
    func saveCurrentLocation(lat: Double, log: Double) {
        startingLocation = CLLocationCoordinate2D(latitude: lat, longitude: log)
    }
}
