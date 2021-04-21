//
//  UpdateSessionParams.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//

import Foundation
import CoreData

final class UpdateSessionParamsService {
    enum Error: Swift.Error {
        case missingContext(FixedSession.FixedMeasurementOutput)
    }
    func updateSessionsParams(session: Session, output: FixedSession.FixedMeasurementOutput) throws {
        session.uuid = output.uuid
        session.type = output.type
    
        session.name = output.title
        session.tags  = output.tag_list
        session.startTime = output.start_time
        session.endTime = output.end_time
        session.version = output.version
        guard let context = session.managedObjectContext else {
            throw Error.missingContext(output)
        }
        #warning("TODO: Rethink to remove old measurements and streams")
        try output.streams.values.forEach { streamOutput in
            let stream: MeasurementStream = try context.newOrExisting(id: streamOutput.id)
            
            stream.sensorName = streamOutput.sensor_name
            stream.sensorPackageName = streamOutput.sensor_package_name
            stream.measurementType = streamOutput.measurement_type
            stream.measurementShortType = streamOutput.measurement_short_type
            stream.unitName = streamOutput.unit_name
            stream.unitSymbol = streamOutput.unit_symbol
            stream.thresholdVeryLow = streamOutput.threshold_very_low
            stream.thresholdLow = streamOutput.threshold_low
            stream.thresholdMedium = streamOutput.threshold_medium
            stream.thresholdHigh = streamOutput.threshold_high
            stream.thresholdVeryHigh = streamOutput.threshold_very_high
            stream.gotDeleted = streamOutput.deleted ?? false
    
            //                            // Save starting thresholds
            //                            let thresholds = SensorThreshold(context: context)
            //                            thresholds.sensorName = streamOutput.sensor_name
            //                            thresholds.thresholdVeryLow = Int32(streamOutput.threshold_very_low)
            //                            thresholds.thresholdLow = Int32(streamOutput.threshold_low)
            //                            thresholds.thresholdMedium = Int32(streamOutput.threshold_medium)
            //                            thresholds.thresholdHigh = Int32(streamOutput.threshold_high)
            //                            thresholds.thresholdVeryHigh = Int32(streamOutput.threshold_very_high)
    
            try streamOutput.measurements.forEach { measurement in
                let newMeasurement: Measurement = try context.newOrExisting(id: measurement.id)
                
                newMeasurement.value = measurement.measured_value
                newMeasurement.latitude = measurement.latitude
                newMeasurement.longitude = measurement.longitude
                newMeasurement.time = measurement.time
                newMeasurement.measurementStream = stream
            }
            session.addToMeasurementStreams(stream)
        }
    
    }
}


