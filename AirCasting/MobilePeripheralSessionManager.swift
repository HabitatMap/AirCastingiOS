// Created by Lunar on 07/06/2021.
//

import Foundation
import CoreBluetooth

struct StreamsIDs {
    var pm1StreamID: MeasurementStreamLocalID?
    var pm2StreamID: MeasurementStreamLocalID?
    var pm10StreamID: MeasurementStreamLocalID?
    var fStreamID: MeasurementStreamLocalID?
    var rhStreamID: MeasurementStreamLocalID?
}

class MobilePeripheralSessionManager {
    private let measurementStreamStorage: MeasurementStreamStorage
    private lazy var locationProvider = LocationProvider()
    
    var activeMobileSession: MobileSession?
    var streamsIDs: [String: MeasurementStreamLocalID] = [:]
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    func startRecording(session: Session, peripheral: CBPeripheral) throws {
        try measurementStreamStorage.createSession(session)
        try measurementStreamStorage.updateSessionStatus(.RECORDING, for: session.uuid)
        activeMobileSession = MobileSession(peripheral: peripheral, session: session)
    }
    
    func handlePeripheralMeasurement(_ measurement: PeripheralMeasurement) {
        print(measurement.measurementStream)
        if activeMobileSession == nil {
            return
        }
        if activeMobileSession?.peripheral == measurement.peripheral {
            try! updateStreams(stream: measurement.measurementStream)
        }
    }
    
    func disconnectPeripheral(_ peripheral: CBPeripheral) {
        if activeMobileSession?.peripheral == peripheral {
            let session = activeMobileSession!.session
            print("DISCONNECTING SESSION")
            
            try! measurementStreamStorage.updateSessionStatus(.DISCONNETCED, for: session.uuid)
        }
    }
    
    private func updateStreams(stream: ABMeasurementStream) throws {
        let  location = locationProvider.currentLocation?.coordinate
        
        if let id = streamsIDs[stream.sensorName] {
            try measurementStreamStorage.addMeasurementValue(stream.measuredValue, at: location, toStreamWithID: id)
        } else {
            try createSessionStream(stream)
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
