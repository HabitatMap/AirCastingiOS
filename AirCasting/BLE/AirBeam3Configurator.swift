//
//  AirBeam3Configuration.swift
//  AirCasting
//
//  Created by Lunar on 02/03/2021.
//

import Foundation
import CoreBluetooth
import CoreLocation

struct AirBeam3Configurator {

    var peripheral: CBPeripheral
    var hexMessageBuilder = HexMessagesBuilder()
    let userDefaults = UserDefaults.standard
    
    // have notifications about new measurements
    private let MEASUREMENTS_CHARACTERISTIC_UUIDS: [CBUUID] = [
        CBUUID(string:"0000ffe1-0000-1000-8000-00805f9b34fb"),    // Temperature
        CBUUID(string:"0000ffe3-0000-1000-8000-00805f9b34fb"),    // Humidity
        CBUUID(string:"0000ffe4-0000-1000-8000-00805f9b34fb"),    // PM1
        CBUUID(string:"0000ffe5-0000-1000-8000-00805f9b34fb"),    // PM2.5
        CBUUID(string:"0000ffe6-0000-1000-8000-00805f9b34fb")]    // PM10
    
    // used for sending hex codes to the AirBeam
    private let CONFIGURATION_CHARACTERISTIC_UUID =  CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    
    // has notifications about measurements count in particular csv file on SD card
    private let DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    
    // has notifications for reading measurements stored in csv files on SD card
    private let DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffdf-0000-1000-8000-00805f9b34fb")
    
    // service id
    private let SERVICE_UUID = CBUUID(string:"0000ffdd-0000-1000-8000-00805f9b34fb")
    
    
    func configure(session: OldSession, wifiSSID: String?, wifiPassword: String?) {
        // TO DO: get location from Session, change the date
        let date = "19/12/19-02:40:00"
        let location = CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0)
        
        // TO DO: pick session type depending on object's session type
        
        // MOBILE
        configureMobileSession(dateString: date, location: location)
        
        //FIXED
        configureFixedWifiSession(location: location,
                                  dateString: date,
                                  wifiSSID: wifiSSID,
                                  wifiPassword: wifiPassword)
    }
    
    private func configureMobileSession(dateString: String, location: CLLocationCoordinate2D) {
        sendLocationConfiguration(location: location)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            sendCurrentTimeConfiguration(date: dateString)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                sendMobileModeRequest()
            }
        }
    }
    
    // To configure fixed session we need to send authMessage first
    // We're generating unique String for session UUID and sending it with users auth token to the AB
    
    private func configureFixed() {
        
        guard let auth = userDefaults.string(forKey: "auth_token") else { return }
        
        sendUUIDRequest(uuid: "fcb242f0-fdba-4c9b-943e-51adff1aebac")
        print("1")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            sendAuthToken(authToken: auth)
            print("2")
        }
    }
    
    private func configureFixedWifiSession(location: CLLocationCoordinate2D, dateString: String, wifiSSID: String?, wifiPassword: String?) {
        // TO DO: Add location
        let  temporaryLocation = CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0)
        
        guard let wifiSSID = wifiSSID,
              let wifiPassword = wifiPassword
        else { return }
        
        sendLocationConfiguration(location: temporaryLocation)
        print("3")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            sendCurrentTimeConfiguration(date: dateString)
            print("4")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                sendWifiConfiguration(wifiSSID: wifiSSID, wifiPassword: wifiPassword)
                print("5")
            }
        }
    }
    
    // MARK: Commands
    
    private func sendUUIDRequest(uuid: String) {
        let message = hexMessageBuilder.uuidMessage(uuid: uuid)
        sendConfigMessage(data: message)
    }
    
    private func sendAuthToken(authToken: String) {
        let message = hexMessageBuilder.authTokenMessage(authToken: authToken)
        sendConfigMessage(data: message!)
    }
    
    private func sendLocationConfiguration(location: CLLocationCoordinate2D) {
        let message = hexMessageBuilder.locationMessage(lat: location.latitude,
                                                           lng: location.longitude)
        sendConfigMessage(data: message)
    }
    
    private func sendCurrentTimeConfiguration(date: String) {
        let message = hexMessageBuilder.currentTimeMessage(date: date)
        sendConfigMessage(data: message)
    }
    
    private func sendMobileModeRequest() {
        let message = hexMessageBuilder.bluetoothConfigurationMessage
        sendConfigMessage(data: message)
    }
    
    private func sendWifiConfiguration(wifiSSID: String, wifiPassword: String) {
        let message = hexMessageBuilder.wifiConfigurationMessage(wifiSSID: wifiSSID,
                                                                 wifiPassword: wifiPassword)
        sendConfigMessage(data: message)
    }
    
    // MARK: Utils
    
    func sendConfigMessage(data: Data) {
        guard let characteristic = getCharacteristic(serviceID: SERVICE_UUID,
                                                     charID: CONFIGURATION_CHARACTERISTIC_UUID) else {
            return
        }
        peripheral.writeValue(data,
                              for: characteristic,
                              type: .withResponse)
    }
    
    func getCharacteristic(serviceID: CBUUID, charID: CBUUID) -> CBCharacteristic? {
        let service = peripheral.services?.first(where: { (service) -> Bool in
            service.uuid == serviceID
        })
        guard let characteristic = service?.characteristics?.first(where: { (characteristic) -> Bool in
            characteristic.uuid == charID
        }) else {
            return nil
        }
        return characteristic
    }
    
}
