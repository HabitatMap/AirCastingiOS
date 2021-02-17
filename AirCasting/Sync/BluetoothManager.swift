//
//  BluetoothManager.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject {
    
    var centralManager = CBCentralManager()
    @Published var devices: [CBPeripheral] = []
    
    var airbeams: [CBPeripheral] {
        devices.filter { (device) -> Bool in
            device.name?.contains("AirBeam") ?? false
        }
    }
    var otherDevices: [CBPeripheral] {
        devices.filter { (device) -> Bool in
            !(device.name?.contains("AirBeam") ?? false)
        }
    }
    
    override init() {
        super.init()
        centralManager.delegate = self
    }
    
    func startScanning() {
        //AirBeam 3 UUID
        //let service = CBUUID(string: "0000ffdd-0000-1000-8000-00805f9b34fb")
        centralManager.scanForPeripherals(withServices: nil,
                                          options: nil)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .unknown:
          print("central.state is .unknown")
        case .resetting:
          print("central.state is .resetting")
        case .unsupported:
          print("central.state is .unsupported")
        case .unauthorized:
          print("central.state is .unauthorized")
        case .poweredOff:
          print("central.state is .poweredOff")
        case .poweredOn:
          print("central.state is .poweredOn")
            startScanning()
        @unknown default:
            fatalError()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !devices.contains(peripheral) {
            if peripheral.name != nil {
                devices.append(peripheral)

            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DeviceConnected"),
                                        object: nil)
        print("Connected to the \(String(describing: peripheral.name))")
    }

}
