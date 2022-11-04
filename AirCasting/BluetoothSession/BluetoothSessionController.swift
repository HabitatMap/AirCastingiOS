// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver

protocol BluetoothSessionController {
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice)
    func stopRecordingSession(with uuid: SessionUUID)
}

class MobileAirBeamSessionRecordingController: BluetoothSessionController {
    @Injected var mobilePeripheralSessionManager: MobilePeripheralSessionManager
    @Injected private var bluetoothManager: NewBluetoothManager
    
    private var measurementsCharacteristics: [String] = [
        "0000ffe1-0000-1000-8000-00805f9b34fb",    // Temperature
        "0000ffe3-0000-1000-8000-00805f9b34fb",    // Humidity
        "0000ffe4-0000-1000-8000-00805f9b34fb",    // PM1
        "0000ffe5-0000-1000-8000-00805f9b34fb",    // PM2.5
        "0000ffe6-0000-1000-8000-00805f9b34fb"]   // PM10
    
    private var characteristicsObservers: [AnyHashable] = []
    
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice) {
        mobilePeripheralSessionManager.startRecording(session: session, peripheral: device.peripheral)
        
        measurementsCharacteristics.forEach {
            let observer = bluetoothManager.subscribeToCharacteristic(for: device, characteristic: .init(value: $0)) { result in
                switch result {
                case .success(let data):
                    guard let measurementData = data else { return }
                    Log.verbose("## measurement: \(measurementData)")
                    if let parsedMeasurement = self.parseData(data: measurementData) {
                        self.mobilePeripheralSessionManager.handlePeripheralMeasurement(PeripheralMeasurement(peripheral: device.peripheral, measurementStream: parsedMeasurement))
                    }
                default:
                    break
                }
            }
            characteristicsObservers.append(observer)
        }
    }
    
    func stopRecordingSession(with uuid: SessionUUID) {
        mobilePeripheralSessionManager.finishSession(with: uuid)
        characteristicsObservers.forEach({ bluetoothManager.unsubscribeCharacteristicObserver(token: $0)})
        characteristicsObservers = []
    }
    
    private func parseData(data: Data) -> ABMeasurementStream? {
        let string = String(data: data, encoding: .utf8)
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
}
