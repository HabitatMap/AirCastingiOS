// Created by Lunar on 07/06/2021.
//

import Foundation
import CoreBluetooth

class MobilePeripheralSessionManager {
    private let measurementStreamStorage: MeasurementStreamStorage
    private lazy var locationProvider = LocationProvider()
    
    private var activeMobileSession: MobileSession?
    
    private var streamsIDs: [SensorName: MeasurementStreamLocalID] = [:]
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func startRecording(session: Session, peripheral: CBPeripheral) throws {
        try measurementStreamStorage.createSession(session)
        locationProvider.requestLocation()
        activeMobileSession = MobileSession(peripheral: peripheral, session: session)
    }
    
    func handlePeripheralMeasurement(_ measurement: PeripheralMeasurement) {
        if activeMobileSession == nil {
            return
        }
        if activeMobileSession?.peripheral == measurement.peripheral {
            do {
                try updateStreams(stream: measurement.measurementStream, sessionUUID: activeMobileSession!.session.uuid) } catch {
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
            
            do {
                try measurementStreamStorage.updateSessionStatus(.FINISHED, for: session.uuid)
                try measurementStreamStorage.updateSessionEndtime(Date(), for: session.uuid)
            } catch {
                Log.error("Unable to change session status to finished because of an error: \(error)")
            }
            centralManger.cancelPeripheralConnection(activeMobileSession!.peripheral)
            activeMobileSession = nil
            locationProvider.stopUpdatingLocation()
        }
    }
    
    private func updateStreams(stream: ABMeasurementStream, sessionUUID: SessionUUID) throws {
        let  location = locationProvider.currentLocation?.coordinate
        let existingStreamID = try? measurementStreamStorage.existingMeasurementStream(sessionUUID, name: stream.sensorName)
        guard let id = existingStreamID else {
            return try createSessionStream(stream, sessionUUID)
        }
        
        try measurementStreamStorage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: id)
    }
    
    private func createSessionStream(_ stream: ABMeasurementStream, _ sessionUUID: SessionUUID) throws {
        let location = locationProvider.currentLocation?.coordinate
        
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
        
        streamsIDs[stream.sensorName] = try measurementStreamStorage.createMeasurementStream(sessionStream, for: sessionUUID)
        try measurementStreamStorage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: streamsIDs[stream.sensorName]!)
    }
}
