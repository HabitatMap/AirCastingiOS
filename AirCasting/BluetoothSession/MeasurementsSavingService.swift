// Created by Lunar on 17/11/2022.
//

import Foundation
import Resolver
import CoreLocation

protocol MeasurementsSavingService {
    func handlePeripheralMeasurement(_ measurement: ABMeasurementStream, sessionUUID: SessionUUID, locationless: Bool)
    func createSession(session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
    func changeStatusToRecording(for sessionUUID: SessionUUID)
}

class DefaultMeasurementsSaver: MeasurementsSavingService {
    @Injected private var persistence: MobileSessionRecordingStorage
    @Injected private var uiStorage: UIStorage
    private var peripheralMeasurementManager = PeripheralMeasurementTimeLocationManager()
    private var expectedMeasurementThreshold = 1

    class PeripheralMeasurementTimeLocationManager {
        @Injected private var locationTracker: LocationTracker

        private(set) var collectedMeasurementsCount: Int = 0
        private(set) var currentTime: Date = DateBuilder.getFakeUTCDate()
        private(set) var currentLocation: CLLocationCoordinate2D? = .undefined

        func startNewValuesRound(locationless: Bool) {
            currentLocation = !locationless ? locationTracker.location.value?.coordinate : .undefined
            currentTime = DateBuilder.getFakeUTCDate()
            collectedMeasurementsCount = 0
        }

        func incrementCounter() { collectedMeasurementsCount += 1 }
    }

    func createSession(session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
           persistence.accessStorage { [weak self] storage in
               do {
                   guard let self else { return }
                   let sessionReturned = try storage.createSession(session)
                   let entity = BluetoothConnectionEntity(context: sessionReturned.managedObjectContext!)
                   entity.peripheralUUID = device.uuid
                   entity.session = sessionReturned
                   self.uiStorage.accessStorage { storage in
                       do {
                           try storage.switchCardExpanded(to: true, sessionUUID: session.uuid)
                       } catch {
                           Log.error("\(error)")
                       }
                   }
                   setMeasurementThreshold(basedOn: entity.session?.deviceType)
                   completion(.success(()))
               } catch {
                   Log.info("\(error)")
                   completion(.failure(error))
               }
           }
       }

    private func setMeasurementThreshold(basedOn type: DeviceType?) {
        /* Explanation: We anticipate receiving 5 measurements from AirBeam 3 and 2 from AirBeam Mini. It's crucial that these batches arrive with timestamps accurate to the second. Therefore, we wait for the expected number of measurements before updating streams with the current time. */
        switch type {
        case .AIRBEAM3:
            expectedMeasurementThreshold = 5
        case .AIRBEAMMINI:
            expectedMeasurementThreshold = 2
        default:
            expectedMeasurementThreshold = 1
            Log.warning("There's an unknown device recording session")
        }
    }
    
    func handlePeripheralMeasurement(_ measurement: ABMeasurementStream, sessionUUID: SessionUUID, locationless: Bool) {
        if peripheralMeasurementManager.collectedMeasurementsCount == expectedMeasurementThreshold {
            peripheralMeasurementManager.startNewValuesRound(locationless: locationless)
        }
        updateStreams(stream: measurement, sessionUUID: sessionUUID, location: peripheralMeasurementManager.currentLocation, time: peripheralMeasurementManager.currentTime)
        peripheralMeasurementManager.incrementCounter()
    }

    func changeStatusToRecording(for sessionUUID: SessionUUID) {
        persistence.accessStorage {
            do {
                try $0.updateSessionStatus(.RECORDING, for: sessionUUID)
            } catch {
                Log.error("Failed to change session status to recording")
            }
        }
    }

    private func updateStreams(stream: ABMeasurementStream, sessionUUID: SessionUUID, location: CLLocationCoordinate2D?, time: Date) {
        persistence.accessStorage { storage in
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

    private func createSessionStream(_ stream: ABMeasurementStream, _ sessionUUID: SessionUUID, storage: HiddenMobileSessionRecordingStorage) throws -> MeasurementStreamLocalID {
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
}
