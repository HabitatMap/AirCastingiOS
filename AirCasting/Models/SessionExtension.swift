//
//  Session.swift
//  AirCasting
//
//  Created by Lunar on 30/03/2021.
//

import Foundation

extension SessionEntity {
    var isMobile: Bool { type == .mobile }
    var isDormant: Bool {
        type == .mobile && status == .FINISHED
    }
    var isFixed: Bool { type == .fixed }
}

extension SessionEntity {
    
    var pm1Stream: MeasurementStreamEntity? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.sensorName == "AirBeam3-PM1"
        })
        let pm1Stream = matach as? MeasurementStreamEntity
        return pm1Stream
    }
    
    var pm2Stream: MeasurementStreamEntity? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.sensorName?.contains("PM2.5") ?? false
        })
        let pm2Stream = matach as? MeasurementStreamEntity
        return pm2Stream
    }
    var pm10Stream: MeasurementStreamEntity? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.sensorName?.contains("PM10") ?? false
        })
        let pm10Stream = matach as? MeasurementStreamEntity
        return pm10Stream
    }
    var FStream: MeasurementStreamEntity? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.measurementShortType == "F"
        })
        let FStream = matach as? MeasurementStreamEntity
        return FStream
    }
    var HStream: MeasurementStreamEntity? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.measurementShortType == "RH"
        })
        let HStream = matach as? MeasurementStreamEntity
        return HStream
    }
    var dbStream: MeasurementStreamEntity? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.measurementShortType == "db"
        })
        let dbStream = matach as? MeasurementStreamEntity
        return dbStream
    }
}
