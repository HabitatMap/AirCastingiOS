// Created by Lunar on 07/06/2021.
//

import Foundation
import CoreBluetooth
import CoreLocation
import Resolver

class MobilePeripheralSessionManager {
    
    class PeripheralMeasurementTimeLocationManager {
        @Injected private var locationTracker: LocationTracker
        
        private(set) var collectedValuesCount: Int = 5
        private(set) var currentTime: Date = DateBuilder.getFakeUTCDate()
        private(set) var currentLocation: CLLocationCoordinate2D? = .undefined
        
        func startNewValuesRound(locationless: Bool) {
            currentLocation = !locationless ? locationTracker.location.value?.coordinate : .undefined
            currentTime = DateBuilder.getFakeUTCDate()
            collectedValuesCount = 0
        }
        
        func incrementCounter() { collectedValuesCount += 1 }
    }
    
    var peripheralMeasurementManager = PeripheralMeasurementTimeLocationManager()
    var isMobileSessionActive: Bool { activeMobileSession != nil }

    private let measurementStreamStorage: MeasurementStreamStorage
    @Injected private var locationTracker: LocationTracker
    @Injected private var uiStorage: UIStorage

    private var activeMobileSession: MobileSession?

    private var streamsIDs: [SensorName: MeasurementStreamLocalID] = [:]

    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }

    func startRecording(session: Session, peripheral: CBPeripheral) {
        measurementStreamStorage.accessStorage { [weak self] storage in
            do {
                let sessionReturned = try storage.createSession(session)
                let entity = BluetoothConnectionEntity(context: sessionReturned.managedObjectContext!)
                entity.peripheralUUID = peripheral.identifier.description
                entity.session = sessionReturned
                guard let self = self else { return }
                self.uiStorage.accessStorage { storage in
                    do {
                        try storage.switchCardExpanded(to: true, sessionUUID: session.uuid)
                    } catch {
                        Log.error("\(error)")
                    }
                }
                DispatchQueue.main.async {
                    if !session.locationless {
                        self.locationTracker.start()
                    }
                    self.activeMobileSession = MobileSession(peripheral: peripheral, session: session)
                }
            } catch {
                Log.info("\(error)")
            }
        }
    }

    func handlePeripheralMeasurement(_ measurement: PeripheralMeasurement) {
        if activeMobileSession == nil {
            return
        }

        if activeMobileSession?.peripheral == measurement.peripheral {
            if peripheralMeasurementManager.collectedValuesCount == 5 { peripheralMeasurementManager.startNewValuesRound(locationless: activeMobileSession!.session.locationless) }
            
            do {
                try updateStreams(stream: measurement.measurementStream, sessionUUID: activeMobileSession!.session.uuid, location: peripheralMeasurementManager.currentLocation, time: peripheralMeasurementManager.currentTime)
            } catch {
                Log.error("Unable to save measurement from airbeam to database because of an error: \(error)")
            }
            
            peripheralMeasurementManager.incrementCounter()
        }
    }
    
    // This function is still needed for when the standalone mode flag is disabled
    func finishSession(for peripheral: CBPeripheral, centralManager: CBCentralManager) {
        if activeMobileSession?.peripheral == peripheral {
            updateDatabaseForFinishedSession(with: activeMobileSession!.session.uuid)
            finishActiveSession(for: peripheral, centralManager: centralManager)
        }
    }

    func finishSession(with uuid: SessionUUID, centralManager: CBCentralManager) {
        measurementStreamStorage.accessStorage { storage in
            do {
                let session = try storage.getExistingSession(with: uuid)
                if session.isActive {
                    guard let activePeripheral = self.activeMobileSession?.peripheral else { return }
                    self.finishActiveSession(for: activePeripheral, centralManager: centralManager)
                }
                self.updateDatabaseForFinishedSession(with: session.uuid)
            } catch {
                Log.error("Unable to change session status to finished because of an error: \(error)")
            }
        }
    }
    
    func finishSession(with uuid: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                let session = try storage.getExistingSession(with: uuid)
                if session.isActive {
                    guard let activeSession = self.activeMobileSession else { return }
                    if !activeSession.session.locationless {
                        self.locationTracker.stop()
                    }
                    
                    self.activeMobileSession = nil
                }
                self.updateDatabaseForFinishedSession(with: session.uuid)
            } catch {
                Log.error("Unable to change session status to finished because of an error: \(error)")
            }
        }
    }

    private func finishActiveSession(for peripheral: CBPeripheral, centralManager: CBCentralManager) {
        guard let activeSession = activeMobileSession, activeMobileSession?.peripheral == peripheral else {
            return
        }

        centralManager.cancelPeripheralConnection(activeSession.peripheral)
        if !activeSession.session.locationless {
            locationTracker.stop()
        }
        
        activeMobileSession = nil
    }

    private func updateDatabaseForFinishedSession(with uuid: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.FINISHED, for: uuid)
                try storage.updateSessionEndtime(DateBuilder.getRawDate(), for: uuid)
            } catch {
                Log.error("Unable to change session status to finished because of an error: \(error)")
            }
        }
    }

    func enterStandaloneMode(sessionUUID: SessionUUID, centralManager: CBCentralManager) {
        guard
            let activePeripheral = activeMobileSession?.peripheral,
            activeMobileSession?.session.uuid == sessionUUID
        else {
            Log.warning("Enter stand alone mode called for session which is not active")
            return
        }
        changeSessionStatusToDisconnected(uuid: sessionUUID)

        centralManager.cancelPeripheralConnection(activePeripheral)
        if !activeMobileSession!.session.locationless {
            locationTracker.stop()
        }
        activeMobileSession = nil
    }

    func moveSessionToStandaloneMode(peripheral: CBPeripheral) {
        guard activeMobileSession?.peripheral == peripheral else {
            Log.warning("Enter standalone mode called for perihperal which is not associated with active session")
            return
        }
        locationTracker.stop()
        activeMobileSession = nil
    }

    func markActiveSessionAsDisconnected(peripheral: CBPeripheral) {
        guard
            let sessionUUID = activeMobileSession?.session.uuid,
            activeMobileSession?.peripheral == peripheral
        else {
            Log.warning("Tried to disconnect session for peripheral which is not associated with an active session")
            return
        }
        Log.info("Changing session status to disconnected for: \(sessionUUID)")
        changeSessionStatusToDisconnected(uuid: sessionUUID)
    }

    private func changeSessionStatusToDisconnected(uuid: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.DISCONNECTED, for: uuid)
            } catch {
                Log.error("Unable to change session status to disconnected because of an error: \(error)")
            }
        }
    }

    private func updateStreams(stream: ABMeasurementStream, sessionUUID: SessionUUID, location: CLLocationCoordinate2D?, time: Date) throws {

        measurementStreamStorage.accessStorage { storage in
            do {
                let existingStreamID = try storage.existingMeasurementStream(sessionUUID, name: stream.sensorName)
                guard let id = existingStreamID else {
                    let streamId = try self.createSessionStream(stream, sessionUUID, storage: storage)
                    try storage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: streamId, on: time)
                    return
                }
                try storage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: id, on: time)
            } catch {
                Log.error("Error saving value from peripheral: \(error)")
            }
        }
    }

    private func createSessionStream(_ stream: ABMeasurementStream, _ sessionUUID: SessionUUID, storage: HiddenCoreDataMeasurementStreamStorage) throws -> MeasurementStreamLocalID {
        let sessionStream = MeasurementStream(id: nil,
                                              sensorName: stream.sensorName,
                                              sensorPackageName: stream.packageName,
                                              measurementType: stream.measurementType,
                                              measurementShortType: stream.measurementShortType,
                                              unitName: stream.unitName,
                                              unitSymbol: stream.unitSymbol,
                                              thresholdVeryHigh: Int32(stream.thresholdVeryHigh),
                                              thresholdHigh: Int32(stream.thresholdHigh),
                                              thresholdMedium: Int32(stream.thresholdMedium),
                                              thresholdLow: Int32(stream.thresholdLow),
                                              thresholdVeryLow: Int32(stream.thresholdVeryLow))

        return try storage.saveMeasurementStream(sessionStream, for: sessionUUID)
    }

    func configureAB() {
        guard let peripheral = activeMobileSession?.peripheral else { return }
        AirBeam3Configurator(peripheral: peripheral)
            .configureMobileSession(
                location: locationTracker.location.value?.coordinate ?? .undefined
            )
    }

    func activeSessionInProgressWith(_ peripheral: CBPeripheral) -> Bool {
        activeMobileSession?.peripheral == peripheral
    }
}


class ReconnectionController: BluetoothConnectionObserver {
    @Injected private var mobilePeripheralManager: MobilePeripheralSessionManager
    @Injected private var bluetoothManager: NewBluetoothManager
    
    init() {
        bluetoothManager.addConnectionObserver(self)
    }
    
    func didDisconnect(device: NewBluetoothManager.BluetoothDevice) {
        guard mobilePeripheralManager.activeSessionInProgressWith(device.peripheral) else { return } // TODO: Move away from CB!
        mobilePeripheralManager.markActiveSessionAsDisconnected(peripheral: device.peripheral)
        
        bluetoothManager.connect(to: device, timeout: 10) { result in
            switch result {
            case .success:
                Log.info("Reconnected to a peripheral: \(device.peripheral)")
                self.bluetoothManager.discoverCharacteristics(for: device, timeout: 10) { result in
                    switch result {
                    case .success:
                        Log.info("Discovered characteristics for: \(device.peripheral)")
                        self.mobilePeripheralManager.configureAB()
                    case .failure(_):
                        self.mobilePeripheralManager.moveSessionToStandaloneMode(peripheral: device.peripheral)
                    }
                }
            case .failure(_):
                self.mobilePeripheralManager.moveSessionToStandaloneMode(peripheral: device.peripheral)
            }
        }
    }
}

protocol MobileSessionRecordingController {
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice)
    func stopRecordingSession(with uuid: SessionUUID)
}

class MobileAirBeamSessionRecordingController: MobileSessionRecordingController {
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
