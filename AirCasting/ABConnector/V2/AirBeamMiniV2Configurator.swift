// Created by Lunar on 30/04/2026.
//

import Foundation
import CoreLocation

struct AirBeamMiniV2Configurator: AirBeamConfigurator {
    enum AirBeamMiniV2ConfiguratorError: Swift.Error {
        case notImplemented
    }

    private let device: any BluetoothDevice

    init(device: any BluetoothDevice) {
        self.device = device
    }

    func configureMobileSession(location: CLLocationCoordinate2D, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AirBeamMiniV2ConfiguratorError.notImplemented))
    }

    func configureSession(uuid: SessionUUID, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AirBeamMiniV2ConfiguratorError.notImplemented))
    }

    func configureFixedCellularSession(uuid: SessionUUID,
                                       location: CLLocationCoordinate2D,
                                       date: Date,
                                       completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AirBeamMiniV2ConfiguratorError.notImplemented))
    }

    func configureFixedWifiSession(uuid: SessionUUID,
                                   location: CLLocationCoordinate2D,
                                   date: Date,
                                   wifiSSID: String,
                                   wifiPassword: String,
                                   completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AirBeamMiniV2ConfiguratorError.notImplemented))
    }

    func configureSDSync(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AirBeamMiniV2ConfiguratorError.notImplemented))
    }

    func clearSDCard(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AirBeamMiniV2ConfiguratorError.notImplemented))
    }
}
