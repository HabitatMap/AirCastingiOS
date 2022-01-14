// Created by Lunar on 07/06/2021.
//

import Foundation
import CoreBluetooth
import CoreLocation

class MobilePeripheralSessionManager {
    private let measurementStreamStorage: MeasurementStreamStorage
    private lazy var locationProvider = LocationProvider()

    private var activeMobileSession: MobileSession?

    private var streamsIDs: [SensorName: MeasurementStreamLocalID] = [:]

    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }

    func startRecording(session: Session, peripheral: CBPeripheral) {
        measurementStreamStorage.accessStorage { [weak self] storage in
            do {
                try storage.createSession(session)
                DispatchQueue.main.async {
                    if !session.locationless {
                        self?.locationProvider.requestLocation()
                    }
                    self?.activeMobileSession = MobileSession(peripheral: peripheral, session: session)
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
            do {
                try updateStreams(stream: measurement.measurementStream, sessionUUID: activeMobileSession!.session.uuid, isLocationTracked: activeMobileSession!.session.locationless)
            } catch {
                Log.error("Unable to save measurement from airbeam to database because of an error: \(error)")
            }
        }
    }
    
    // This function is still needed for when the standalone mode flag is disabled
    func finishSession(for peripheral: CBPeripheral, centralManager: CBCentralManager) {
        if activeMobileSession?.peripheral == peripheral {
            finishActiveSession(for: peripheral, centralManager: centralManager)
            updateDatabaseForFinishedSession(with: activeMobileSession!.session.uuid)
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

    private func finishActiveSession(for peripheral: CBPeripheral, centralManager: CBCentralManager) {
        guard let activeSession = activeMobileSession, activeMobileSession?.peripheral == peripheral else {
            return
        }

        centralManager.cancelPeripheralConnection(activeSession.peripheral)
        if activeSession.session.locationless {
            locationProvider.stopUpdatingLocation()
        }
        activeMobileSession = nil
    }

    private func updateDatabaseForFinishedSession(with uuid: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.FINISHED, for: uuid)
                try storage.updateSessionEndtime(Date(), for: uuid)
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
            locationProvider.stopUpdatingLocation()
        }
        activeMobileSession = nil
    }

    func moveSessionToStandaloneMode(peripheral: CBPeripheral) {
        guard activeMobileSession?.peripheral == peripheral else {
            Log.warning("Enter standalone mode called for perihperal which is not associated with active session")
            return
        }

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

    private func updateStreams(stream: ABMeasurementStream, sessionUUID: SessionUUID, isLocationTracked: Bool) throws {
        let  location = isLocationTracked ? locationProvider.currentLocation?.coordinate : CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0)

        measurementStreamStorage.accessStorage { storage in
            do {
                let existingStreamID = try storage.existingMeasurementStream(sessionUUID, name: stream.sensorName)
                guard let id = existingStreamID else {
                    return try self.createSessionStream(stream, sessionUUID)
                }
                try storage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: id)
            } catch {
                Log.info("\(error)")
            }
        }
    }

    private func createSessionStream(_ stream: ABMeasurementStream, _ sessionUUID: SessionUUID) throws {
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

        measurementStreamStorage.accessStorage { [self] storage in
            do {
                streamsIDs[stream.sensorName] = try storage.saveMeasurementStream(sessionStream, for: sessionUUID)
            } catch {
                Log.info("\(error)")
            }
        }
    }

    func configureAB(userAuthenticationSession: UserAuthenticationSession) {
        guard let peripheral = activeMobileSession?.peripheral else { return }
        locationProvider.requestLocation()
        AirBeam3Configurator(userAuthenticationSession: userAuthenticationSession,
                             peripheral: peripheral)
            .configureMobileSession(
                location: locationProvider.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0)
            )
    }

    func activeSessionInProgressWith(_ peripheral: CBPeripheral) -> Bool {
        activeMobileSession?.peripheral == peripheral
    }
}
