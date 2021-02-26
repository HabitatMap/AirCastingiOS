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
    @Published var isScanning: Bool = true
    var observed: NSKeyValueObservation?
    
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
        isScanning = centralManager.isScanning
        
        observed = centralManager.observe(\.isScanning) { [weak self] _, change in
            self?.isScanning = self?.centralManager.isScanning ?? false
        }
    }
    
    func startScanning() {
        //AirBeam 3 UUID
        //let service = CBUUID(string: "0000ffdd-0000-1000-8000-00805f9b34fb")
        centralManager.scanForPeripherals(withServices: nil,
                                          options: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30)) {
            self.centralManager.stopScan()
        }
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
        
        // Here's code for getting data from AB.
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected.")
    }
    
}

extension BluetoothManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
                print("didDiscoverServices \(peripheral.discoverCharacteristics(nil, for: service))")
            }

        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                peripheral.readValue(for: characteristic)
        
                print("didDiscoverCharacteristicsFor: \(peripheral.readValue(for: characteristic))")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        characteristic.value
        
        print("didUpdateValueFor: \(String(data: characteristic.value!, encoding: .utf8))")
    }
    
    func parseData(data: Data) -> [String] {
        let string = String(data: data, encoding: .utf8)
        let components = string?.components(separatedBy: ";")
        
        return components ?? []
    }
}
