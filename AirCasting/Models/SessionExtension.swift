//
//  Session.swift
//  AirCasting
//
//  Created by Lunar on 30/03/2021.
//

import Foundation

extension Session {
    
    var pm1Stream: MeasurementStream? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStream)?.sensorName?.contains("PM1") ?? false
        })
        let pm1Stream = matach as? MeasurementStream
        return pm1Stream
    }
    
    var pm2Stream: MeasurementStream? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStream)?.sensorName?.contains("PM2.5") ?? false
        })
        let pm2Stream = matach as? MeasurementStream
        return pm2Stream
    }
    var pm10Stream: MeasurementStream? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStream)?.sensorName?.contains("PM10") ?? false
        })
        let pm10Stream = matach as? MeasurementStream
        return pm10Stream
    }
    var FStream: MeasurementStream? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStream)?.measurementShortType == "F"
        })
        let FStream = matach as? MeasurementStream
        return FStream
    }
    var HStream: MeasurementStream? {
        let matach = measurementStreams?.first(where: { (stream) -> Bool in
            (stream as? MeasurementStream)?.measurementShortType == "RH"
        })
        let HStream = matach as? MeasurementStream
        return HStream
    }
}
