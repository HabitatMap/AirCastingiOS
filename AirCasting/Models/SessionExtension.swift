//
//  Session.swift
//  AirCasting
//
//  Created by Lunar on 30/03/2021.
//

import Foundation

extension SessionEntity {
    var isMobile: Bool { type == .mobile }
    var isActive: Bool { type == .mobile && status == .RECORDING }
    var isDormant: Bool { type == .mobile && status == .FINISHED }
    var isFixed: Bool { type == .fixed }
    var isFollowed: Bool { followedAt != nil }
}

extension SessionEntity {
    
    var pm1Stream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.sensorName == "AirBeam3-PM1" ||
                (stream as? MeasurementStreamEntity)?.sensorName == "AirBeam2-PM1" ||
                    (stream as? MeasurementStreamEntity)?.sensorName == "AirBeam1-PM1"
        })
        let pm1Stream = match as? MeasurementStreamEntity
        return pm1Stream
    }
    
    var pm2Stream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.sensorName?.contains("PM2.5") ?? false
        })
        let pm2Stream = match as? MeasurementStreamEntity
        return pm2Stream
    }
    var pm10Stream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.sensorName?.contains("PM10") ?? false
        })
        let pm10Stream = match as? MeasurementStreamEntity
        return pm10Stream
    }
    var FStream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.measurementShortType == "F"
        })
        let FStream = match as? MeasurementStreamEntity
        return FStream
    }
    var HStream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.measurementShortType == "RH"
        })
        let HStream = match as? MeasurementStreamEntity
        return HStream
    }
    var dbStream: MeasurementStreamEntity? {
        let match = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStreamEntity)?.measurementShortType == "db"
        })
        let dbStream = match as? MeasurementStreamEntity
        return dbStream
    }
}
