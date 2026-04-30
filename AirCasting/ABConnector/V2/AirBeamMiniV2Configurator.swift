// Created by Lunar on 30/04/2026.
//

import Foundation
import CoreLocation
import CoreBluetooth
import Resolver

final class AirBeamMiniV2Configurator: AirBeamConfigurator {
    enum AirBeamMiniV2ConfiguratorError: Swift.Error {
        case notImplemented
        case statusDecodeFailed
        case statusTimeout
        case missingCharacteristic
    }

    @Injected private var btCommunicator: BluetoothCommunicator
    @Injected private var btPeripheral: BluetoothPeripheralConfigurator

    private let device: any BluetoothDevice
    private let queue = DispatchQueue(label: "ab.v2.configurator")

    private var subscriptionTokens: [AnyHashable] = []
    private(set) var lastStatus: V2BinaryProtocol.Status?

    private var statusAwaiter: ((Result<V2BinaryProtocol.Status, Error>) -> Void)?
    private var fallbackReadWorkItem: DispatchWorkItem?

    init(device: any BluetoothDevice) {
        self.device = device
    }

    deinit {
        teardown()
    }

    /// Phase 1 entry point: subscribe to all 4 notifying V2 chars, settle 300ms, await first Status.
    /// Returns the first decoded Status (also retained on `lastStatus` for callers).
    /// If no Status notification arrives within `statusFallbackReadDelaySeconds`, an explicit read is issued.
    func subscribeAndAwaitStatus(timeout: TimeInterval = 5.0,
                                 completion: @escaping (Result<V2BinaryProtocol.Status, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.statusAwaiter = completion

            self.subscribe(uuid: V2BinaryProtocol.CharacteristicUUIDs.status) { [weak self] result in
                self?.handleStatusNotification(result)
            }
            self.subscribe(uuid: V2BinaryProtocol.CharacteristicUUIDs.response) { result in
                Log.verbose("V2 response notification: \(String(describing: result))")
            }
            self.subscribe(uuid: V2BinaryProtocol.CharacteristicUUIDs.measurement) { result in
                Log.verbose("V2 measurement notification: \(String(describing: result))")
            }
            self.subscribe(uuid: V2BinaryProtocol.CharacteristicUUIDs.sync) { result in
                Log.verbose("V2 sync notification: \(String(describing: result))")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + V2BinaryProtocol.settleDelaySeconds) { [weak self] in
                self?.scheduleStatusFallbackRead()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.queue.async {
                    guard let self = self, let awaiter = self.statusAwaiter else { return }
                    self.statusAwaiter = nil
                    self.fallbackReadWorkItem?.cancel()
                    awaiter(.failure(AirBeamMiniV2ConfiguratorError.statusTimeout))
                }
            }
        }
    }

    func teardown() {
        queue.sync {
            self.fallbackReadWorkItem?.cancel()
            self.fallbackReadWorkItem = nil
            self.statusAwaiter = nil
            for token in self.subscriptionTokens {
                _ = self.btCommunicator.unsubscribeCharacteristicObserver(token: token)
            }
            self.subscriptionTokens.removeAll()
        }
    }

    private func subscribe(uuid: CBUUID, notify: @escaping (Result<Data?, Error>) -> Void) {
        do {
            let token = try btCommunicator.subscribeToCharacteristic(
                for: device,
                characteristic: CharacteristicUUID(value: uuid.uuidString),
                notify: notify
            )
            subscriptionTokens.append(token)
        } catch {
            Log.error("V2 subscribe to \(uuid) failed: \(error)")
        }
    }

    private func scheduleStatusFallbackRead() {
        queue.async { [weak self] in
            guard let self = self, self.lastStatus == nil else { return }
            let work = DispatchWorkItem { [weak self] in
                guard let self = self, self.lastStatus == nil else { return }
                Log.info("V2 status fallback read after no notification within \(V2BinaryProtocol.statusFallbackReadDelaySeconds)s")
                do {
                    try self.btPeripheral.readValue(
                        for: self.device,
                        serviceID: V2BinaryProtocol.ServiceUUID.v2.uuidString,
                        characteristicID: V2BinaryProtocol.CharacteristicUUIDs.status.uuidString
                    )
                } catch {
                    Log.error("V2 status fallback read failed: \(error)")
                }
            }
            self.fallbackReadWorkItem = work
            self.queue.asyncAfter(deadline: .now() + V2BinaryProtocol.statusFallbackReadDelaySeconds, execute: work)
        }
    }

    private func handleStatusNotification(_ result: Result<Data?, Error>) {
        queue.async { [weak self] in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                guard let data = data else {
                    Log.error("V2 status notification missing data")
                    return
                }
                switch V2BinaryProtocol.decodeStatus(data) {
                case .success(let status):
                    Log.info("V2 status decoded: \(status)")
                    self.lastStatus = status
                    self.fallbackReadWorkItem?.cancel()
                    let awaiter = self.statusAwaiter
                    self.statusAwaiter = nil
                    awaiter?(.success(status))
                case .failure(let error):
                    Log.error("V2 status decode failed: \(error) raw=\(data as NSData)")
                    let awaiter = self.statusAwaiter
                    self.statusAwaiter = nil
                    awaiter?(.failure(AirBeamMiniV2ConfiguratorError.statusDecodeFailed))
                }
            case .failure(let error):
                Log.error("V2 status notification error: \(error)")
                let awaiter = self.statusAwaiter
                self.statusAwaiter = nil
                awaiter?(.failure(error))
            }
        }
    }

    // MARK: - AirBeamConfigurator (V2 wiring lands in later phases)

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
