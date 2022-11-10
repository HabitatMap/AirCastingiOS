//
//  AirBeam3Configuration.swift
//  AirCasting
//
//  Created by Lunar on 02/03/2021.
//

import Foundation
import CoreLocation
import Resolver

protocol AirBeamConfigurator {
    func configureMobileSession(location: CLLocationCoordinate2D, completion: @escaping (Result<Void, Error>) -> Void)
    func configureFixed(uuid: SessionUUID, completion: @escaping (Result<Void, Error>) -> Void)
    func configureFixedCellularSession(uuid: SessionUUID,
                                       location: CLLocationCoordinate2D,
                                       date: Date,
                                       completion: @escaping (Result<Void, Error>) -> Void)
    func configureFixedWifiSession(uuid: SessionUUID,
                                   location: CLLocationCoordinate2D,
                                   date: Date,
                                   wifiSSID: String,
                                   wifiPassword: String,
                                   completion: @escaping (Result<Void, Error>) -> Void)
    func configureSDSync(completion: @escaping (Result<Void, Error>) -> Void)
    func clearSDCard(completion: @escaping (Result<Void, Error>) -> Void)
}

struct AirBeam3Configurator: AirBeamConfigurator {
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
    private let serviceUUID = "0000ffdd-0000-1000-8000-00805f9b34fb"

    init(device: NewBluetoothManager.BluetoothDevice) {
        self.device = device
    }
    
    func configureMobileSession(location: CLLocationCoordinate2D, completion: @escaping (Result<Void, Error>) -> Void) {
        Log.info("Starting configuring mobile session.")
        sendLocationConfiguration(location: location) { result in
            switch result {
            case .success():
                let dateString = dateFormatter.string(from: DateBuilder.getFakeUTCDate())
                sendCurrentTimeConfiguration(date: dateString) { result in
                    switch result {
                    case .success():
                        sendMobileModeRequest(completion: completion)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func configureFixedWifiSession(uuid: SessionUUID,
                                   location: CLLocationCoordinate2D,
                                   date: Date,
                                   wifiSSID: String,
                                   wifiPassword: String,
                                   completion: @escaping (Result<Void, Error>) -> Void) {
        // IS THIS DELAY NECESSARY??
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            sendLocationConfiguration(location: location) { result in
                switch result {
                case .success():
                    let dateString = dateFormatter.string(from: date)
                    sendCurrentTimeConfiguration(date: dateString) { result in
                        switch result {
                        case .success():
                            sendWifiConfiguration(wifiSSID: wifiSSID, wifiPassword: wifiPassword, completion: completion)
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func configureFixedCellularSession(uuid: SessionUUID,
                                       location: CLLocationCoordinate2D,
                                       date: Date,
                                       completion: @escaping (Result<Void, Error>) -> Void) {
        // IS THIS DELAY NECESSARY??
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            sendLocationConfiguration(location: location) { result in
                switch result {
                case .success():
                    let dateString = dateFormatter.string(from: date)
                    sendCurrentTimeConfiguration(date: dateString) { result in
                        switch result {
                        case .success():
                            sendCellularConfiguration(completion: completion)
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // To configure fixed session we need to send authMessage first
    // We're generating unique String for session UUID and sending it with users auth token to the AB
    func configureFixed(uuid: SessionUUID, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = userAuthenticationSession.token else {
            completion(.failure(AirBeam3ConfiguratorError.missingAuthenticationToken))
            return
        }
        sendUUIDRequest(uuid: uuid) { result in
            switch result {
            case .success():
                sendAuthToken(authToken: token, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func configureSDSync(completion: @escaping (Result<Void, Error>) -> Void) {
        downloadFromSDCardModeRequest(completion: completion)
    }
    
    func clearSDCard(completion: @escaping (Result<Void, Error>) -> Void) {
        clearSDCardModeRequest(completion: completion)
    }
}

private extension AirBeam3Configurator {
    private func sendUUIDRequest(uuid: SessionUUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let message = hexMessageBuilder.uuidMessage(uuid: uuid)
        Log.info("Sending UUID request to peripheral")
        sendConfigMessage(data: message, completion: completion)
    }
    
    private func sendAuthToken(authToken: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let message = hexMessageBuilder.authTokenMessage(authToken: authToken) else { return }
        Log.info("Sending auth token to peripheral")
        sendConfigMessage(data: message, completion: completion)
    }
    
    private func sendLocationConfiguration(location: CLLocationCoordinate2D, completion: @escaping (Result<Void, Error>) -> Void) {
        let message = hexMessageBuilder.locationMessage(lat: location.latitude,
                                                           lng: location.longitude)
        Log.info("Sending location configuration to peripheral")
        sendConfigMessage(data: message, completion: completion)
    }
    
    private func sendCurrentTimeConfiguration(date: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let message = hexMessageBuilder.currentTimeMessage(date: date)
        Log.info("Sending time configuration to peripheral")
        sendConfigMessage(data: message, completion: completion)
    }
    
    private func sendMobileModeRequest(completion: @escaping (Result<Void, Error>) -> Void) {
        let message = hexMessageBuilder.bluetoothConfigurationMessage
        Log.info("Sending mobile mode request to peripheral")
        sendConfigMessage(data: message, completion: completion)
    }
    
    private func sendWifiConfiguration(wifiSSID: String, wifiPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let message = hexMessageBuilder.wifiConfigurationMessage(wifiSSID: wifiSSID,
                                                                 wifiPassword: wifiPassword)
        Log.info("Sending wifi configuration to peripheral")
        sendConfigMessage(data: message, completion: completion)
    }
    
    private func sendCellularConfiguration(completion: @escaping (Result<Void, Error>) -> Void) {
        let message = hexMessageBuilder.cellularconfigurationCode
        Log.info("Sending cellular configuration to peripheral")
        sendConfigMessage(data: message, completion: completion)
    }
    
    private func downloadFromSDCardModeRequest(completion: @escaping (Result<Void, Error>) -> Void) {
        let message = hexMessageBuilder.downloadFromSDCardModeRequest
        Log.info("Sending download from SD card mode request to peripheral")
        sendConfigMessage(data: message, completion: completion)
    }
    
    private func clearSDCardModeRequest(completion: @escaping (Result<Void, Error>) -> Void) {
        let message = hexMessageBuilder.clearSDCardModeRequest
        Log.info("Sending clear SD card mode request to peripheral")
        sendConfigMessage(data: message, completion: completion)
    }
    
    private func sendConfigMessage(data: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        btManager.sendMessage(data: data, to: device, serviceID: serviceUUID, characteristicID: configurationCharacteristicUUID, completion: completion)
    }
}
