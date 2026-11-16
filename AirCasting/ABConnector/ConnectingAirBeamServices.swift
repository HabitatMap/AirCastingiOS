// Created by Lunar on 30/07/2021.
//

import Foundation
import Resolver

enum AirBeamServicesConnectionResult: Equatable {
    static func == (lhs: AirBeamServicesConnectionResult, rhs: AirBeamServicesConnectionResult) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success):
            return true
        case (.timeout, .timeout):
            return true
        case (.deviceBusy, .deviceBusy):
            return true
        case (.incompatibleDevice, .incompatibleDevice):
            return true
        case (.unknown(let error1), .unknown(let error2)):
            return error1?.localizedDescription == error2?.localizedDescription
        default:
            return false
        }
    }
    
    case success
    case timeout
    case deviceBusy
    case incompatibleDevice
    case unknown(Error?)
}

protocol ConnectingAirBeamServices {
    func connect(to device: any BluetoothDevice, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void)
    func disconnect(from device: any BluetoothDevice)
}

class ConnectingAirBeamServicesBluetooth: ConnectingAirBeamServices {
    @Injected private var btManager: BluetoothConnectionHandler
    @Injected private var btState: BluetoothStateHandler
    private var connectionToken: AnyObject?
    private var airBeamCharacteristics = ["FFDE", "FFDF", "FFE1", "FFE3", "FFE4", "FFE5", "FFE6"]
    private var activeV2Configurators: [String: AirBeamMiniV2Configurator] = [:]
    private let v2Lock = NSRecursiveLock()

    func connect(to device: any BluetoothDevice, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        Log.info("Starting Airbeam connection (firmware: \(device.firmwareVersion))")
        do {
            try btManager.connect(to: device, timeout: timeout) { result in
                do {
                    _ = try result.get()
                    try self.btManager.discoverCharacteristics(for: device, timeout: timeout) { characteristicsResult in
                        switch characteristicsResult {
                        case .success(let characteristics):
                            self.handleDiscoveredCharacteristics(characteristics, device: device, completion: completion)
                        case .failure(let error):
                            Log.error("Failed to discover characteristics: \(error)")
                            completion(.timeout)
                        }
                    }
                } catch let bluetoothError as BluetoothManager.BluetoothDriverError {
                    switch bluetoothError {
                    case .timeout:
                        completion(.timeout)
                    case .deviceBusy:
                        completion(.deviceBusy)
                    case .unknown:
                        completion(.unknown(nil))
                    case .characteristicNotFound:
                        completion(.unknown(bluetoothError))
                    }
                } catch {
                    completion(.unknown(error))
                }
            }
        } catch {
            completion(.unknown(error))
        }
    }

    func disconnect(from device: any BluetoothDevice) {
        v2Lock.lock()
        if let configurator = activeV2Configurators.removeValue(forKey: device.uuid) {
            configurator.teardown()
        }
        v2Lock.unlock()
        do {
            try btManager.disconnect(from: device)
        } catch {
            Log.error("Failed to disconnect: \(error)")
        }
    }

    private func handleDiscoveredCharacteristics(_ characteristics: [BluetoothManager.BluetoothCharacteristic],
                                                 device: any BluetoothDevice,
                                                 completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        let uuids = characteristics.map(\.UUID)
        switch device.firmwareVersion {
        case .v1:
            completion(isCompatibile(uuids) ? .success : .incompatibleDevice)
        case .v2:
            guard isV2Compatible(uuids) else {
                Log.error("V2 device missing required characteristics. found=\(uuids)")
                completion(.incompatibleDevice)
                return
            }
            let configurator = Resolver.resolve(AirBeamMiniV2Configurator.self, args: device)
            v2Lock.lock()
            activeV2Configurators[device.uuid] = configurator
            v2Lock.unlock()

            // V2 configurator is cached per-device for the app's lifetime
            // (V2ConfiguratorRegistry), so a prior connect/disconnect cycle —
            // e.g. SD sync teardown — leaves a stale `lastStatus` cache and
            // CoreBluetooth-invalidated subscription tokens behind. Without a
            // reset, `subscribeAndAwaitStatus` short-circuits on the cache,
            // no fresh notify subscriptions get armed, and the next
            // `configureSession` write (GetSensors) silently times out because
            // its response notification has nowhere to land — UI sits forever
            // on the Connecting screen. `prepareForReconnect` clears the
            // cache, drops stale tokens, and re-arms subscriptions on the
            // following `subscribeAndAwaitStatus`. ReconnectionController
            // already does this on its path; the user-initiated connect path
            // needs the same treatment.
            configurator.prepareForReconnect()

            configurator.subscribeAndAwaitStatus { result in
                switch result {
                case .success(let status):
                    Log.info("V2 connection ready. Status=\(status)")
                    completion(.success)
                case .failure(let error):
                    Log.error("V2 status setup failed: \(error)")
                    completion(.unknown(error))
                }
            }
        }
    }

    private func isCompatibile(_ uuids: [String]) -> Bool {
        airBeamCharacteristics.allSatisfy({ uuids.contains($0) })
    }

    private func isV2Compatible(_ uuids: [String]) -> Bool {
        let normalized = Set(uuids.map { $0.uppercased() })
        return V2BinaryProtocol.CharacteristicUUIDs.all.allSatisfy { normalized.contains($0.uuidString.uppercased()) }
    }
}
