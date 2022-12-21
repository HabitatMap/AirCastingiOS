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

    func connect(to device: any BluetoothDevice, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        Log.info("Starting Airbeam connection")
        do {
            try btManager.connect(to: device, timeout: timeout) { result in
                do {
                    _ = try result.get()
                    try self.btManager.discoverCharacteristics(for: device, timeout: timeout) { characteristicsResult in
                        switch characteristicsResult {
                        case .success(let characteristics):
                            completion(self.isCompatibile(characteristics.map(\.UUID)) ? .success : .incompatibleDevice)
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
        do {
            try btManager.disconnect(from: device)
        } catch {
            Log.error("Failed to disconnect: \(error)")
        }
    }
    
    private func isCompatibile(_ uuids: [String]) -> Bool {
        airBeamCharacteristics.allSatisfy({ uuids.contains($0) })
    }
}
