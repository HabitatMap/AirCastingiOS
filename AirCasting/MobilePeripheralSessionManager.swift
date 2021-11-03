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
    
    func finishActiveSession(centralManger: CBCentralManager) {
        guard let activePeripheral = activeMobileSession?.peripheral else { return }
        finishSession(for: activePeripheral, centralManger: centralManger)
    }
    
    func finishSession(for peripheral: CBPeripheral, centralManger: CBCentralManager) {
        if activeMobileSession?.peripheral == peripheral {
            let session = activeMobileSession!.session
            
            measurementStreamStorage.accessStorage { storage in
                do {
                    try storage.updateSessionStatus(.FINISHED, for: session.uuid)
                    try storage.updateSessionEndtime(Date(), for: session.uuid)
                } catch {
                    Log.error("Unable to change session status to finished because of an error: \(error)")
                }
            }
            centralManger.cancelPeripheralConnection(activeMobileSession!.peripheral)
            activeMobileSession = nil
            locationProvider.stopUpdatingLocation()
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
                                date: Date().currentUTCTimeZoneDate,
                                location: CLLocationCoordinate2D(latitude: 200, longitude: 200))
    }
    
    func activeSessionInProgressWith(_ peripheral: CBPeripheral) -> Bool {
        activeMobileSession?.peripheral == peripheral
    }
}
