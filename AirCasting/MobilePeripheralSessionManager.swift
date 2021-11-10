// Created by Lunar on 07/06/2021.
//

import Foundation
import CoreBluetooth
import CoreLocation

class MobilePeripheralSessionManager {
    private let measurementStreamStorage: MeasurementStreamStorage
    private lazy var locationProvider = LocationProvider()
    
    private var activeMobileSession: MobileSession?
    private var standaloneModeSessions: [MobileSession] = []
    
    private var streamsIDs: [SensorName: MeasurementStreamLocalID] = [:]
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func startRecording(session: Session, peripheral: CBPeripheral) {
        measurementStreamStorage.accessStorage { [weak self] storage in
            do {
                try storage.createSession(session)
                DispatchQueue.main.async {
                    self?.locationProvider.requestLocation()
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
                try updateStreams(stream: measurement.measurementStream, sessionUUID: activeMobileSession!.session.uuid)
            } catch {
                Log.error("Unable to save measurement from airbeam to database because of an error: \(error)")
            }
        }
    }
    
    func finishSession(for peripheral: CBPeripheral, centralManager: CBCentralManager) {
        if activeMobileSession?.peripheral == peripheral {
            finishActiveSession(for: peripheral, centralManager: centralManager)
        } else {
            guard let mobileSession = standaloneModeSessions.first(where: { $0.peripheral == peripheral }) else {
                    assertionFailure("Finishing session was called for unknown peripheral")
                    return
                }
            updateDatabaseForFinishedSession(with: mobileSession.session.uuid)
            standaloneModeSessions.removeAll(where: { $0.peripheral == peripheral })
        }
    }
    
    func finishSession(with uuid: SessionUUID, centralManager: CBCentralManager) {
        if activeMobileSession?.session.uuid == uuid {
            guard let activePeripheral = activeMobileSession?.peripheral else { return }
            finishActiveSession(for: activePeripheral, centralManager: centralManager)
        } else {
            guard standaloneModeSessions.map( { $0.session.uuid } ).contains(uuid) else {
                assertionFailure("Finishing session was called for session which is not in stand alone mode")
                return
            }
            updateDatabaseForFinishedSession(with: uuid)
            standaloneModeSessions.removeAll(where: { $0.session.uuid == uuid })
        }
    }
    
    func finishActiveSession(for peripheral: CBPeripheral, centralManager: CBCentralManager) {
        if activeMobileSession?.peripheral == peripheral {
            let session = activeMobileSession!.session
            
            updateDatabaseForFinishedSession(with: session.uuid)
            centralManager.cancelPeripheralConnection(activeMobileSession!.peripheral)
            activeMobileSession = nil
            locationProvider.stopUpdatingLocation()
        }
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
        measurementStreamStorage.accessStorage { storage in
            do {
                Log.info("## SESSION DISCONNECTED")
                try storage.updateSessionStatus(.DISCONNECTED, for: sessionUUID)
            } catch {
                Log.error("Unable to change session status to disconnected because of an error: \(error)")
            }
        }
        centralManager.cancelPeripheralConnection(activePeripheral)
        standaloneModeSessions.append(activeMobileSession!)
        activeMobileSession = nil
        locationProvider.stopUpdatingLocation()
    }
    
    func markActiveSessionAsDisconnected(peripheral: CBPeripheral) {
        guard
            let sessionUUID = activeMobileSession?.session.uuid,
            activeMobileSession?.peripheral == peripheral
        else {
            return
        }
        measurementStreamStorage.accessStorage { storage in
            do {
                Log.info("## SESSION DISCONNECTED")
                try storage.updateSessionStatus(.DISCONNECTED, for: sessionUUID)
            } catch {
                Log.error("Unable to change session status to disconnected because of an error: \(error)")
            }
        }
    }
    
    private func updateStreams(stream: ABMeasurementStream, sessionUUID: SessionUUID) throws {
        let  location = locationProvider.currentLocation?.coordinate
                
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
                streamsIDs[stream.sensorName] = try storage.createMeasurementStream(sessionStream, for: sessionUUID)
            } catch {
                Log.info("\(error)")
            }
        }
    }
    
    func configureAB(userAuthenticationSession: UserAuthenticationSession) {
        guard let peripheral = activeMobileSession?.peripheral else { return }
        AirBeam3Configurator(userAuthenticationSession: userAuthenticationSession,
                             peripheral: peripheral).configureMobileSession(
                                location: CLLocationCoordinate2D(latitude: 200, longitude: 200))
    }
    
    func activeSessionInProgressWith(_ peripheral: CBPeripheral) -> Bool {
        activeMobileSession?.peripheral == peripheral
    }
}
