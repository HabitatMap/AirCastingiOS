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
        let service = CBUUID(string: "00001101-0000-1000-8000-00805F9B34FB")
        // TO DO: add CBUUID
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
