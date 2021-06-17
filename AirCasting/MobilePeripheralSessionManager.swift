// Created by Lunar on 07/06/2021.
//

import Foundation
import CoreBluetooth

class MobilePeripheralSessionManager {
    private let measurementStreamStorage: MeasurementStreamStorage
    private lazy var locationProvider = LocationProvider()
    
    private var activeMobileSession: MobileSession?
    
    private var streamsIDs: [String: MeasurementStreamLocalID] = [:]
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func startRecording(session: Session, peripheral: CBPeripheral) throws {
        try measurementStreamStorage.createSession(session)
        try measurementStreamStorage.updateSessionStatus(.NEW, for: session.uuid)
        locationProvider.requestLocation()
        activeMobileSession = MobileSession(peripheral: peripheral, session: session)
    }
    
    func handlePeripheralMeasurement(_ measurement: PeripheralMeasurement) {
        if activeMobileSession == nil {
            return
        }
        if activeMobileSession?.peripheral == measurement.peripheral {
            updateStreams(stream: measurement.measurementStream)
        }
    }
    
    func finishSession(for peripheral: CBPeripheral) {
        if activeMobileSession?.peripheral == peripheral {
            let session = activeMobileSession!.session
            
            try! measurementStreamStorage.updateSessionStatus(.FINISHED, for: session.uuid)
            activeMobileSession = nil
            locationProvider.stopUpdatingLocation()
        }
    }
    
    private func updateStreams(stream: ABMeasurementStream) {
        let  location = locationProvider.currentLocation?.coordinate
        
        do {
            if let id = streamsIDs[stream.sensorName] {
                try measurementStreamStorage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: id)
            } else {
                try createSessionStream(stream)
            } } catch {
                Log.error("Unable to save measurement from airbeam to database because of an error: \(error)")
            }
    }
    
    private func createSessionStream(_ stream: ABMeasurementStream) throws {
        let  location = locationProvider.currentLocation?.coordinate
        
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
        streamsIDs[stream.sensorName] = try measurementStreamStorage.createMeasurementStream(sessionStream, for: activeMobileSession!.session.uuid)
        try measurementStreamStorage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: streamsIDs[stream.sensorName]!)
    }
}
