//
//  AirBeam3Configuration.swift
//  AirCasting
//
//  Created by Lunar on 02/03/2021.
//

import Foundation
import CoreLocation
import Resolver

struct AirBeam3Configurator {
    enum AirBeam3ConfiguratorError: Swift.Error {
        case missingAuthenticationToken
    }
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    @Injected private var btManager: NewBluetoothManager
    private let device: NewBluetoothManager.BluetoothDevice
    private let hexMessageBuilder = HexMessagesBuilder()
    private let dateFormatter: DateFormatter = DateFormatters.AirBeam3Configurator.usLocaleFullDateDateFormatter
    
    // used for sending hex codes to the AirBeam
    private let configurationCharacteristicUUID = "0000ffde-0000-1000-8000-00805f9b34fb"
    
    // service id
    private let serviceUUID = "0000ffdd-0000-1000-8000-00805f9b34fb"

    init(device: NewBluetoothManager.BluetoothDevice) {
        self.device = device
    }
    
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
        guard let message = hexMessageBuilder.authTokenMessage(authToken: authToken) else { return }
        Log.info("Sending auth token to peripheral")
        sendConfigMessage(data: message)
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
        Log.info("Sending download from SD card mode request to peripheral")
        sendConfigMessage(data: message)
    }
    
    private func clearSDCardModeRequest() {
        let message = hexMessageBuilder.clearSDCardModeRequest
        Log.info("Sending clear SD card mode request to peripheral")
        sendConfigMessage(data: message)
    }
    
    private func sendConfigMessage(data: Data) {
        btManager.sendMessage(data: data, to: device, serviceID: serviceUUID, characteristicID: configurationCharacteristicUUID)
    }
}
