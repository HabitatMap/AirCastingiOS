//
//  AirBeam3Configuration.swift
//  AirCasting
//
//  Created by Lunar on 02/03/2021.
//

import Foundation
import CoreBluetooth
import CoreLocation
import Resolver

struct AirBeam3Configurator {
    enum AirBeam3ConfiguratorError: Swift.Error {
        case missingAuthenticationToken
    }
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    let peripheral: CBPeripheral

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
    }
    
    private let hexMessageBuilder = HexMessagesBuilder()
    private let dateFormatter: DateFormatter = DateFormatters.AirBeam3Configurator.usLocaleFullDateDateFormatter
    
    // have notifications about new measurements
    private let MEASUREMENTS_CHARACTERISTIC_UUIDS: [CBUUID] = [
        CBUUID(string:"0000ffe1-0000-1000-8000-00805f9b34fb"),    // Temperature
        CBUUID(string:"0000ffe3-0000-1000-8000-00805f9b34fb"),    // Humidity
        CBUUID(string:"0000ffe4-0000-1000-8000-00805f9b34fb"),    // PM1
        CBUUID(string:"0000ffe5-0000-1000-8000-00805f9b34fb"),    // PM2.5
        CBUUID(string:"0000ffe6-0000-1000-8000-00805f9b34fb")]    // PM10
    
    // used for sending hex codes to the AirBeam
    private let CONFIGURATION_CHARACTERISTIC_UUID = CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    
    // has notifications about measurements count in particular csv file on SD card
    private let DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    
    // has notifications for reading measurements stored in csv files on SD card
    private let DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffdf-0000-1000-8000-00805f9b34fb")
    
    // service id
    private let SERVICE_UUID = CBUUID(string:"0000ffdd-0000-1000-8000-00805f9b34fb")
    
    func configureMobileSession(location: CLLocationCoordinate2D) {
        Log.info("Starting configuring mobile session.")
        sendLocationConfiguration(location: location)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            let dateString = dateFormatter.string(from: DateBuilder.getFakeUTCDate())
            sendCurrentTimeConfiguration(date: dateString)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                sendMobileModeRequest()
            }
        }
    }

    func configureFixedWifiSession(uuid: SessionUUID,
                                   location: CLLocationCoordinate2D,
                                   date: Date,
                                   wifiSSID: String,
                                   wifiPassword: String) throws {
        let dateString = dateFormatter.string(from: date)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            sendLocationConfiguration(location: location)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                sendCurrentTimeConfiguration(date: dateString)
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    sendWifiConfiguration(wifiSSID: wifiSSID, wifiPassword: wifiPassword)
                }
            }
        }
    }
    
    func configureFixedCellularSession(uuid: SessionUUID,
                                       location: CLLocationCoordinate2D,
                                       date: Date) throws {
        let dateString = dateFormatter.string(from: date)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            sendLocationConfiguration(location: location)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                sendCurrentTimeConfiguration(date: dateString)
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    sendCellularConfiguration()
                }
            }
        }
    }
    
    // To configure fixed session we need to send authMessage first
    // We're generating unique String for session UUID and sending it with users auth token to the AB
    func configureFixed(uuid: SessionUUID) throws {
        guard let token = userAuthenticationSession.token else {
            throw AirBeam3ConfiguratorError.missingAuthenticationToken
        }
        sendUUIDRequest(uuid: uuid)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            sendAuthToken(authToken: token)
        }
    }
    
    func configureSDSync() {
        downloadFromSDCardModeRequest()
    }
    
    func clearSDCard() {
        clearSDCardModeRequest()
    }
}

private extension AirBeam3Configurator {
    
    // MARK: Commands
    private func sendUUIDRequest(uuid: SessionUUID) {
        let message = hexMessageBuilder.uuidMessage(uuid: uuid)
        Log.info("Sending UUID request to peripheral")
        sendConfigMessage(data: message)
    }
    
    private func sendAuthToken(authToken: String) {
        let message = hexMessageBuilder.authTokenMessage(authToken: authToken)
        Log.info("Sending auth token to peripheral")
        sendConfigMessage(data: message!)
    }
    
    private func sendLocationConfiguration(location: CLLocationCoordinate2D) {
        let message = hexMessageBuilder.locationMessage(lat: location.latitude,
                                                           lng: location.longitude)
        Log.info("Sending location configuration to peripheral")
        sendConfigMessage(data: message)
    }
    
    private func sendCurrentTimeConfiguration(date: String) {
        let message = hexMessageBuilder.currentTimeMessage(date: date)
        Log.info("Sending time configuration to peripheral")
        sendConfigMessage(data: message)
    }
    
    private func sendMobileModeRequest() {
        let message = hexMessageBuilder.bluetoothConfigurationMessage
        Log.info("Sending mobile mode request to peripheral")
        sendConfigMessage(data: message)
    }
    
    private func sendWifiConfiguration(wifiSSID: String, wifiPassword: String) {
        let message = hexMessageBuilder.wifiConfigurationMessage(wifiSSID: wifiSSID,
                                                                 wifiPassword: wifiPassword)
        Log.info("Sending wifi configuration to peripheral")
        sendConfigMessage(data: message)
    }
    
    private func sendCellularConfiguration() {
        let message = hexMessageBuilder.cellularconfigurationCode
        Log.info("Sending cellular configuration to peripheral")
        sendConfigMessage(data: message)
    }
    
    private func downloadFromSDCardModeRequest() {
        let message = hexMessageBuilder.downloadFromSDCardModeRequest
        sendConfigMessage(data: message)
    }
    
    private func clearSDCardModeRequest() {
        let message = hexMessageBuilder.clearSDCardModeRequest
        sendConfigMessage(data: message)
    }
    
    // MARK: Utils
    
    func sendConfigMessage(data: Data) {
        guard let characteristic = getCharacteristic(serviceID: SERVICE_UUID,
                                                     charID: CONFIGURATION_CHARACTERISTIC_UUID) else {
            assertionFailure("Unable to get characteristic from \(peripheral)")
            return
        }
        Log.info("Writing value to peripheral")
        peripheral.writeValue(data,
                              for: characteristic,
                              type: .withResponse)
    }
    
    func getCharacteristic(serviceID: CBUUID, charID: CBUUID) -> CBCharacteristic? {
        Log.info("Getting characteristics for peripheral. Peripheral services: \(String(describing: peripheral.services?.count))")
        let service = peripheral.services?.first(where: { data -> Bool in
            data.uuid == serviceID
        })
        Log.info("Service characteristics: \(String(describing: service?.characteristics?.count))")
        guard let characteristic = service?.characteristics?.first(where: { characteristic -> Bool in
            characteristic.uuid == charID
        }) else {
            return nil
        }
        return characteristic
    }
}
