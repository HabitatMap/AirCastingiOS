// Created by Lunar on 17/11/2022.
//

import Foundation
import Resolver
import CoreLocation

protocol MeasurementsSavingService {
    func handlePeripheralMeasurement(_ measurement: ABMeasurementStream, sessionUUID: SessionUUID, locationless: Bool)
    func createSession(session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
    func changeStatusToRecording(for sessionUUID: SessionUUID)
    /// V2 path: save a single measurement with the device-provided timestamp.
    /// Bypasses the V1 batching path used for AB3/Mini-V1 (which generates a fake current time per N readings).
    func saveV2LiveMeasurement(_ measurement: ABMeasurementStream,
                               sessionUUID: SessionUUID,
                               time: Date,
                               locationless: Bool)
    /// V2 path: save a synced measurement using the device-stored timestamp.
    /// Firmware doesn't persist per-record GPS, so callers pass a
    /// `locationOverride` resolved via [[v2-location-backfill-coordinator]] (matched
    /// to the record timestamp against the phone-side sample buffer). When the
    /// override is nil (no buffered match), we fall back to the phone's last-known
    /// fix. Pass `locationless: true` to keep the row coordinate-free.
    func saveV2SyncMeasurement(_ measurement: ABMeasurementStream,
                               sessionUUID: SessionUUID,
                               time: Date,
                               locationless: Bool,
                               locationOverride: CLLocationCoordinate2D?)
}

class DefaultMeasurementsSaver: MeasurementsSavingService {
    @Injected private var persistence: MobileSessionRecordingStorage
    @Injected private var uiStorage: UIStorage
    private var peripheralMeasurementManager: PeripheralMeasurementTimeLocationManager?
    private var expectedMeasurementThreshold = 1

    class PeripheralMeasurementTimeLocationManager {
        @Injected private var locationTracker: LocationTracker

        private(set) var collectedMeasurementsCount: Int
        private(set) var currentTime: Date
        private(set) var currentLocation: CLLocationCoordinate2D?
        
        init(collectedMeasurementsCount: Int) {
            self.collectedMeasurementsCount = collectedMeasurementsCount
            self.currentTime = DateBuilder.getFakeUTCDate()
            self.currentLocation = .undefined
        }

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
                entity.firmwareVersionRaw = Int16(device.firmwareVersion == .v2 ? 1 : 0)
                entity.session = sessionReturned
                self.uiStorage.accessStorage { storage in
                    do {
                        try storage.switchCardExpanded(to: true, sessionUUID: session.uuid)
                    } catch {
                        Log.error("\(error)")
                    }
                }
                setMeasurementThreshold(basedOn: device.airbeamType)
                peripheralMeasurementManager = .init(collectedMeasurementsCount: expectedMeasurementThreshold)
                completion(.success(()))
            } catch {
                Log.info("\(error)")
                completion(.failure(error))
            }
        }
    }
    
    private func setMeasurementThreshold(basedOn type: AirBeamDeviceType?) {
        /* Explanation: We anticipate receiving 5 measurements from AirBeam 3 and 2 from AirBeam Mini. It's crucial that these batches arrive with timestamps accurate to the second. Therefore, we wait for the expected number of measurements before updating streams with the current time. */
        switch type {
        case .airBeam3:
            expectedMeasurementThreshold = 5
        case .airBeamMini:
            expectedMeasurementThreshold = 2
        default:
            expectedMeasurementThreshold = 1
            Log.warning("There's an unknown device recording session")
        }
    }

    func handlePeripheralMeasurement(_ measurement: ABMeasurementStream, sessionUUID: SessionUUID, locationless: Bool) {
        guard let peripheralMeasurementManager else {
            Log.error("Peripheral Measurements Manager should have been initialized during session creation...")
            return
        }
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

    func saveV2LiveMeasurement(_ measurement: ABMeasurementStream,
                               sessionUUID: SessionUUID,
                               time: Date,
                               locationless: Bool) {
        // Resolve LocationTracker lazily inside the call so DefaultMeasurementsSaver
        // (eagerly built at app boot via the BluetoothSessionRecordingController inject
        // chain) doesn't force CLLocationManager init during launch.
        let location: CLLocationCoordinate2D
        if locationless {
            location = .undefined
        } else {
            let tracker = Resolver.resolve(LocationTracker.self)
            location = tracker.location.value?.coordinate ?? .undefined
        }
        updateStreams(stream: measurement, sessionUUID: sessionUUID, location: location, time: time)
    }

    func saveV2SyncMeasurement(_ measurement: ABMeasurementStream,
                               sessionUUID: SessionUUID,
                               time: Date,
                               locationless: Bool,
                               locationOverride: CLLocationCoordinate2D?) {
        // Prefer the backfill-coordinator match (phone GPS captured at the record's
        // timestamp during the disconnect window). Fall back to the phone's last
        // known fix when no buffered match exists — preserves pre-backfill behavior
        // for cold-launch races, permission-denied gaps, and outside-tolerance
        // timestamps.
        let location: CLLocationCoordinate2D
        if locationless {
            location = .undefined
        } else if let locationOverride {
            location = locationOverride
        } else {
            let tracker = Resolver.resolve(LocationTracker.self)
            location = tracker.location.value?.coordinate ?? .undefined
        }
        updateStreams(stream: measurement, sessionUUID: sessionUUID, location: location, time: time)
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
