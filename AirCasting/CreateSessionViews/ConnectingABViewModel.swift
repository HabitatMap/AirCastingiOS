// Created by Lunar on 21/07/2021.
//

import CoreBluetooth
import Foundation

protocol BluetoothConnector {
    func connect(to peripheral: CBPeripheral)
    func cancelPeripheralConnection(for peripheral: CBPeripheral)
}

enum AirBeamServicesConnectionResult {
    case success
    case timeout
    case deviceBusy
}

protocol ConnectingAirBeamServices {
    func connect(to peripheral: CBPeripheral, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void)
}

class ConnectingAirBeamServicesBluetooth: ConnectingAirBeamServices {
    
    private var connectionInProgress = false
    let bluetoothConnector: BluetoothConnector
    
    init(bluetoothConnector: BluetoothConnector) {
        self.bluetoothConnector = bluetoothConnector
    }
    
    func connect(to peripheral: CBPeripheral, timeout: TimeInterval, completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        guard !connectionInProgress else { completion(.deviceBusy); return }
        bluetoothConnector.connect(to: peripheral)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(timeout))) {
            if peripheral.state == .connecting {
                Log.info("Connecting to bluetooth device failed")
                self.bluetoothConnector.cancelPeripheralConnection(for: peripheral)
                completion(.timeout)
            }
        }
        let token = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "DeviceConnected"), object: nil, queue: nil) { _ in
            completion(.success)
            NotificationCenter.default.removeObserver(token)
        }
    }
}

class DefaultAirBeamConnectionController: AirBeamConnectionController {
    let connectingAirBeamServices: ConnectingAirBeamServices
    func connectToAirBeam(peripheral: CBPeripheral, completion: @escaping (Bool) -> Void) {
        connectingAirBeamServices.connect(to: peripheral, timeout: 10) { result in
            switch result {
            case .success:
                completion(true)
            case .deviceBusy, .timeout:
                completion(false)
            }
        }
    }
    
    init(connectingAirBeamServices: ConnectingAirBeamServices) {
        self.connectingAirBeamServices = connectingAirBeamServices
    }
}

protocol AirBeamConnectionController {
    func connectToAirBeam(peripheral: CBPeripheral, completion: @escaping (Bool) -> Void)
}

import SwiftUI

class ConnectingABViewModel {
    @State var shouldDismiss: Bool = false
    @State var isDeviceConnected: Bool = false
    private let airBeamConnectionController: AirBeamConnectionController
    
    init(airBeamConnectionController: AirBeamConnectionController) {
        self.airBeamConnectionController = airBeamConnectionController
    }
    
    func connectToAirBeam(peripheral: CBPeripheral) {
        self.airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { success in
            if success {
                self.isDeviceConnected = true
            } else {
                self.isDeviceConnected = false
                self.shouldDismiss = true
            }
        }
    }
}

extension BluetoothManager: BluetoothConnector {
    func connect(to peripheral: CBPeripheral) {
        self.centralManager.connect(peripheral, options: nil)
    }
    
    func cancelPeripheralConnection(for peripheral: CBPeripheral) {
        self.centralManager.cancelPeripheralConnection(peripheral)
    }
}
