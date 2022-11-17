// Created by Lunar on 07/06/2021.
//

import Foundation
import CoreLocation
import Resolver

//Change name to saver
class MobilePeripheralSessionManager {
//    class PeripheralMeasurementTimeLocationManager {
//        @Injected private var locationTracker: LocationTracker
//
//        private(set) var collectedValuesCount: Int = 5
//        private(set) var currentTime: Date = DateBuilder.getFakeUTCDate()
//        private(set) var currentLocation: CLLocationCoordinate2D? = .undefined
//
//        func startNewValuesRound(locationless: Bool) {
//            currentLocation = !locationless ? locationTracker.location.value?.coordinate : .undefined
//            currentTime = DateBuilder.getFakeUTCDate()
//            collectedValuesCount = 0
//        }
//
//        func incrementCounter() { collectedValuesCount += 1 }
//    }
    
    
    // Used to protect screen when bt session is recording
    var isMobileSessionActive: Bool { activeMobileSession != nil }
    
    @Injected private var locationTracker: LocationTracker
    @Injected private var uiStorage: UIStorage
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    @Injected private var btManager: BluetoothConnectionHandler
    
    // Used for adding right time and location to all 5 streams
//    private var peripheralMeasurementManager = PeripheralMeasurementTimeLocationManager()
    var activeMobileSession: MobileSession?
    
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice) {
        measurementStreamStorage.accessStorage { [weak self] storage in
            do {
                let sessionReturned = try storage.createSession(session)
                let entity = BluetoothConnectionEntity(context: sessionReturned.managedObjectContext!)
                entity.peripheralUUID = device.uuid
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
                    self.activeMobileSession = MobileSession(device: device, session: session)
                }
            } catch {
                // Handle error
                Log.info("\(error)")
            }
        }
    }
    
//    func handlePeripheralMeasurement(_ measurement: AirBeamMeasurement) {
//        guard activeMobileSession?.device == measurement.device else { return }
//
//        if peripheralMeasurementManager.collectedValuesCount == 5 { peripheralMeasurementManager.startNewValuesRound(locationless: activeMobileSession!.session.locationless) }
//
//        updateStreams(stream: measurement.measurementStream, sessionUUID: activeMobileSession!.session.uuid, location: peripheralMeasurementManager.currentLocation, time: peripheralMeasurementManager.currentTime)
//        peripheralMeasurementManager.incrementCounter()
//    }
    
    func activeSessionInProgressWith(_ device: NewBluetoothManager.BluetoothDevice) -> Bool {
        activeMobileSession?.device == device
    }
    
    // This function was used when standalone mode flag was disabled. Make sure we are handing this situation now
    func finishSession(for device: NewBluetoothManager.BluetoothDevice) {
        if activeMobileSession?.device == device {
            updateDatabaseForFinishedSession(with: activeMobileSession!.session.uuid)
            finishActiveSession(for: device)
        }
    }
    
    func finishSession(with uuid: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                let session = try storage.getExistingSession(with: uuid)
                if session.isActive {
                    guard let activeSession = self.activeMobileSession else { return }
                    self.finishActiveSession(for: activeSession.device)
                }
                self.updateDatabaseForFinishedSession(with: session.uuid)
            } catch {
                Log.error("Unable to change session status to finished because of an error: \(error)")
            }
        }
    }
    
//    func enterStandaloneMode(sessionUUID: SessionUUID) {
//        guard let device = activeMobileSession?.device, activeMobileSession?.session.uuid == sessionUUID else {
//            Log.warning("Enter stand alone mode called for session which is not active")
//            return
//        }
//        
//        changeSessionStatusToDisconnected(uuid: sessionUUID)
//        btManager.disconnect(from: device)
//        if !activeMobileSession!.session.locationless {
//            locationTracker.stop()
//        }
//        
//        activeMobileSession = nil
//    }
    
    // Make sure we disconnect from peripheral elsewhere
    private func finishActiveSession(for device: NewBluetoothManager.BluetoothDevice) {
        guard let activeSession = activeMobileSession, let device = activeMobileSession?.device else {
            return
        }
        
        btManager.disconnect(from: device)
        if !activeSession.session.locationless {
            locationTracker.stop()
        }
        
        self.activeMobileSession = nil
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

    private func changeSessionStatusToDisconnected(uuid: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.DISCONNECTED, for: uuid)
            } catch {
                Log.error("Unable to change session status to disconnected because of an error: \(error)")
            }
        }
    }

//    private func updateStreams(stream: ABMeasurementStream, sessionUUID: SessionUUID, location: CLLocationCoordinate2D?, time: Date) {
//        measurementStreamStorage.accessStorage { storage in
//            do {
//                let existingStreamID = try storage.existingMeasurementStream(sessionUUID, name: stream.sensorName)
//                guard let id = existingStreamID else {
//                    let streamId = try self.createSessionStream(stream, sessionUUID, storage: storage)
//                    try storage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: streamId, on: time)
//                    return
//                }
//                try storage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: id, on: time)
//            } catch {
//                Log.error("Error saving value from peripheral: \(error)")
//            }
//        }
//    }

//    private func createSessionStream(_ stream: ABMeasurementStream, _ sessionUUID: SessionUUID, storage: HiddenCoreDataMeasurementStreamStorage) throws -> MeasurementStreamLocalID {
//        let sessionStream = MeasurementStream(id: nil,
//                                              sensorName: stream.sensorName,
//                                              sensorPackageName: stream.packageName,
//                                              measurementType: stream.measurementType,
//                                              measurementShortType: stream.measurementShortType,
//                                              unitName: stream.unitName,
//                                              unitSymbol: stream.unitSymbol,
//                                              thresholdVeryHigh: Int32(stream.thresholdVeryHigh),
//                                              thresholdHigh: Int32(stream.thresholdHigh),
//                                              thresholdMedium: Int32(stream.thresholdMedium),
//                                              thresholdLow: Int32(stream.thresholdLow),
//                                              thresholdVeryLow: Int32(stream.thresholdVeryLow))
//
//        return try storage.saveMeasurementStream(sessionStream, for: sessionUUID)
//    }
}

