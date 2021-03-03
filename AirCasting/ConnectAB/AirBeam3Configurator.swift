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

    let peripheral: CBPeripheral
    let bluetoothManager: BluetoothManager
    var hexMessageBuilder = HexMessagesBuilder()
    
    // have notifications about new measurements
    private var MEASUREMENTS_CHARACTERISTIC_UUIDS: [CBUUID] = [
        CBUUID(string:"0000ffe1-0000-1000-8000-00805f9b34fb"),    // Temperature
        CBUUID(string:"0000ffe3-0000-1000-8000-00805f9b34fb"),    // Humidity
        CBUUID(string:"0000ffe4-0000-1000-8000-00805f9b34fb"),    // PM1
        CBUUID(string:"0000ffe5-0000-1000-8000-00805f9b34fb"),    // PM2.5
        CBUUID(string:"0000ffe6-0000-1000-8000-00805f9b34fb")]    // PM10
    
    // used for sending hex codes to the AirBeam
    private var CONFIGURATION_CHARACTERISTIC_UUID =  CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    // has notifications about measurements count in particular csv file on SD card
    private var DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    // has notifications for reading measurements stored in csv files on SD card
    private var DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffdf-0000-1000-8000-00805f9b34fb")
    // service id
    private var SERVICE_UUID = CBUUID(string:"0000ffdd-0000-1000-8000-00805f9b34fb")
    
    var MAX_MTU = 517
    
    private func configureMobileSession(dateString: String) {
        let location = CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0)
        
        sendLocationConfiguration(location: location)
        sendCurrentTimeConfiguration(date: dateString)
            mobileModeRequest()
    }

    
    func configure(session: Session, wifiSSID: String?, wifiPassword: String?) {
        // TO DO: get location from Session, change the date
        let date = "19/12/19-02:40:00"
        configureMobileSession(dateString: date)
    }
    
    
    // MARK: Commands
    
    private func sendLocationConfiguration(location: CLLocationCoordinate2D) {
        let message = hexMessageBuilder.locationMessage(lat: location.latitude,
                                                           lng: location.longitude)
        sendConfigMessage(data: message)
    }
    
    private func sendCurrentTimeConfiguration(date: String) {
        let message = hexMessageBuilder.currentTimeMessage(date: date)
        sendConfigMessage(data: message)
    }
    
    private func mobileModeRequest() {
        let message = hexMessageBuilder.bluetoothConfigurationMessage
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
