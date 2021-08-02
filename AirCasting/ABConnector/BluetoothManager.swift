//
//  BluetoothManager.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject {
    
    lazy var centralManager: CBCentralManager = {
        let centralManager = CBCentralManager()
        centralManager.delegate = self
        isScanning = centralManager.isScanning
        observed = centralManager.observe(\.isScanning) { [weak self] _, change in
            self?.isScanning = self?.centralManager.isScanning ?? false
        }
        return centralManager
    }()
    
    @Published var isConnected = true
    @Published var devices: [CBPeripheral] = []
    @Published var isScanning: Bool = true
    @Published var centralManagerState: CBManagerState = .unknown
    var observed: NSKeyValueObservation?
    
    let mobilePeripheralSessionManager: MobilePeripheralSessionManager
    
    private var MEASUREMENTS_CHARACTERISTIC_UUIDS: [CBUUID] = [
        CBUUID(string:"0000ffe1-0000-1000-8000-00805f9b34fb"),    // Temperature
        CBUUID(string:"0000ffe3-0000-1000-8000-00805f9b34fb"),    // Humidity
        CBUUID(string:"0000ffe4-0000-1000-8000-00805f9b34fb"),    // PM1
        CBUUID(string:"0000ffe5-0000-1000-8000-00805f9b34fb"),    // PM2.5
        CBUUID(string:"0000ffe6-0000-1000-8000-00805f9b34fb")]   // PM10
    
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
    
    func startScanning() {
        //AirBeam 3 UUID
        //let service = CBUUID(string: "0000ffdd-0000-1000-8000-00805f9b34fb")
        centralManager.scanForPeripherals(withServices: nil,
                                          options: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30)) { [centralManager] in
            centralManager.stopScan()
        }
    }
    
    init(mobilePeripheralSessionManager: MobilePeripheralSessionManager) {
        self.mobilePeripheralSessionManager = mobilePeripheralSessionManager
    }
}

struct PeripheralMeasurement {
    let peripheral: CBPeripheral
    let measurementStream: ABMeasurementStream
}

extension BluetoothManager: CBCentralManagerDelegate {
        
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralManagerState = central.state
        
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
            // App starts looking for peripherals when blueooth is powered on.
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
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DeviceConnected"), object: nil)
        // Here's code for getting data from AB.
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected: \(String(describing: error?.localizedDescription))")
        isConnected = false
        mobilePeripheralSessionManager.finishSession(for: peripheral)
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
                for char in MEASUREMENTS_CHARACTERISTIC_UUIDS {
                    if char == characteristic.uuid {
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                }
            }
        }
    }
    
    func sendHexCode() {
        #warning("TODO: Send it")
        _ = CBUUID(string: "0000ffde-0000-1000-8000-00805f9b34fb")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if MEASUREMENTS_CHARACTERISTIC_UUIDS.contains(characteristic.uuid) {
            guard let value = characteristic.value else {
                Log.warning("AirBeam sent measurement without value")
                return
            }
            if let parsedMeasurement = parseData(data: value) {
                mobilePeripheralSessionManager.handlePeripheralMeasurement(PeripheralMeasurement(peripheral: peripheral, measurementStream: parsedMeasurement))
            }
        }
    }
    
    func parseData(data: Data) -> ABMeasurementStream? {
        let string = String(data: data, encoding: .utf8)
        let components = string?.components(separatedBy: ";")
        #warning("TODO: Check if values contains 11 elements and throw appropriate error")
        guard let values = components,
              let measuredValue = Double(values[0]),
              let thresholdVeryLow = Int(values[7]),
              let thresholdLow = Int(values[8]),
              let thresholdMedium = Int(values[9]),
              let thresholdHigh = Int(values[10]),
              let thresholdVeryHigh = Int(values[11])
        else  {
            return nil
        }
        let newMeasurement = ABMeasurementStream(measuredValue: measuredValue,
                                          packageName: values[1],
                                          sensorName: values[2],
                                          measurementType: values[3],
                                          measurementShortType: values[4],
                                          unitName: values[5],
                                          unitSymbol: values[6],
                                          thresholdVeryLow: thresholdVeryLow,
                                          thresholdLow: thresholdLow,
                                          thresholdMedium: thresholdMedium,
                                          thresholdHigh: thresholdHigh,
                                          thresholdVeryHigh: thresholdVeryHigh)
        return newMeasurement
    }
}
