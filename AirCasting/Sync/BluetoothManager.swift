//
//  BluetoothManager.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject {
    
    var centralManager = CBCentralManager()
    
    override init() {
        super.init()
        centralManager.delegate = self
    }
    
    func startScanning() {
        //AirBeam 3 UUID
        let service = CBUUID(string: "0000ffdd-0000-1000-8000-00805f9b34fb")
        centralManager.scanForPeripherals(withServices: [service],
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
        @unknown default:
            fatalError()
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("NAME: \(peripheral.name), ID: \(peripheral.identifier)")
    }

}
