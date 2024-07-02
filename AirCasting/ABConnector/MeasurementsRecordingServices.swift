// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver

protocol MeasurementsRecordingServices {
    func record(with device: any BluetoothDevice, completion: @escaping (ABMeasurementStream) -> Void)
    func stopRecording()
}

class AirbeamMeasurementsRecordingServices: MeasurementsRecordingServices {
    @Injected private var bluetoothManager: BluetoothCommunicator
    @InjectedObject private var notificationService: NotificationsManager
    
    private var measurementsCharacteristics: [String] = [
        "0000ffe1-0000-1000-8000-00805f9b34fb",    // Temperature
        "0000ffe3-0000-1000-8000-00805f9b34fb",    // Humidity
        "0000ffe4-0000-1000-8000-00805f9b34fb",    // PM1
        "0000ffe5-0000-1000-8000-00805f9b34fb",    // PM2.5
        "0000ffe6-0000-1000-8000-00805f9b34fb"]   // PM10
    
    private var miniMeasurementsCharacteristics: [String] = [
        "0000ffe4-0000-1000-8000-00805f9b34fb",    // PM1
        "0000ffe5-0000-1000-8000-00805f9b34fb",     // PM2.5
        "0000ffe7-0000-1000-8000-00805f9b34fb"      // Battery
        ]
    
    private var characteristicsObservers: [AnyHashable] = []
    private var currentBatteryLvl: Int = -5
    private var batteryBelowTreshold: Bool = false
    
    func record(with device: any BluetoothDevice, completion: @escaping (ABMeasurementStream) -> Void) {
        do {
            let characteristics = device.airbeamType == .airBeamMini ? miniMeasurementsCharacteristics : measurementsCharacteristics
            try characteristics.forEach {
                let observer = try bluetoothManager.subscribeToCharacteristic(for: device, characteristic: .init(value: $0)) { result in
                    switch result {
                    case .success(let data):
                        guard let measurementData = data else { return }
                        if let parsedMeasurement = self.parseData(data: measurementData) {
                            completion(parsedMeasurement)
                        }
                    default:
                        break
                    }
                }
                characteristicsObservers.append(observer)
            }
        } catch {
            Log.error("Failed to subscribe to characteristics: \(error)")
        }
    }
    
    func stopRecording() {
        characteristicsObservers.forEach({ bluetoothManager.unsubscribeCharacteristicObserver(token: $0)})
        characteristicsObservers = []
    }

    private func parseData(data: Data) -> ABMeasurementStream? {
        let string = String(data: data, encoding: .utf8)
        
        if string?.components(separatedBy: ";").count == 1 { // device sent battery level, not a measurement
            sendBatteryLoadInformationNotification(value: string)
            return nil
        }
        
        let components = string?.components(separatedBy: ";")
        guard let values = components,
              values.count == 12,
              let measuredValue = Double(values[0]),
              let thresholdVeryLow = Int(values[7]),
              let thresholdLow = Int(values[8]),
              let thresholdMedium = Int(values[9]),
              let thresholdHigh = Int(values[10]),
              let thresholdVeryHigh = Int(values[11])
        else  {
            Log.warning("Device didn't send expected values")
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
    
    private func sendBatteryLoadInformationNotification(value: String?){
        // Information on a battery load comes in a format:
        // "3.56V  53% Load"

        guard let value else { return }
        
        let components = value.components(separatedBy: " ")
        guard components.count == 4 else { return }
        let percentage = components[2] // e.g. 53%
        guard let percentageNumber = Int(percentage.dropLast(1)) else { return } // e.g. 53
        let range = currentBatteryLvl-2...currentBatteryLvl+1
        
        if (percentageNumber < 15 && !batteryBelowTreshold && !range.contains(percentageNumber)) {
            notificationService.send(notification: .init(title: "AirBeam battery",
                                                         body: "Battery low: \(percentage) Charge your Airbeam."),
                                     visability: .prominent,
                                     for: .lowBattery)
            currentBatteryLvl = percentageNumber
            batteryBelowTreshold = true
            return
        }
        
        if (percentageNumber > 20 && batteryBelowTreshold && !range.contains(percentageNumber)) {
            batteryBelowTreshold = false
            currentBatteryLvl = percentageNumber
        }
        
        
        if (!range.contains(percentageNumber)) {
            currentBatteryLvl = percentageNumber
            notificationService.send(notification: .init(title: "AirBeam battery",
                                                         body: "Current level: \(percentage)"),
                                     for: .battery)
        }
    }
}
