//
//  UpdateSessionParams.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//

import Foundation
import CoreData

class UpdateSessionParamsService {
    
    var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    func updateSessionsParams(session: Session, output: FixedSession.FixedMeasurementOutput) {
        let dateFormatter = ISO8601DateFormatter.defaultLong
    
        session.id = Int64(output.id)
        session.uuid = output.uuid
        session.type = SessionType.from(string: output.type)?.rawValue ?? -1
    
        session.name = output.title
        session.tags  = output.tag_list
        session.startTime  = dateFormatter.date(from: output.start_time)
        session.endTime  = dateFormatter.date(from: output.end_time)
        session.version = Int16(output.version)
    
        for (_, streamOutput) in output.streams {
            let stream: MeasurementStream = self.context.newOrExisting(id: streamOutput.id)
            
            stream.sensorName = streamOutput.sensor_name
            stream.sensorPackageName = streamOutput.sensor_package_name
            stream.measurementType = streamOutput.measurement_type
            stream.measurementShortType = streamOutput.measurement_short_type
            stream.unitName = streamOutput.unit_name
            stream.unitSymbol = streamOutput.unit_symbol
            stream.thresholdVeryLow = Int32(streamOutput.threshold_very_low)
            stream.thresholdLow = Int32(streamOutput.threshold_low)
            stream.thresholdMedium = Int32(streamOutput.threshold_medium)
            stream.thresholdHigh = Int32(streamOutput.threshold_high)
            stream.thresholdVeryHigh = Int32(streamOutput.threshold_very_high)
            stream.gotDeleted = streamOutput.deleted ?? false
    
            //                            // Save starting thresholds
            //                            let thresholds = SensorThreshold(context: context)
            //                            thresholds.sensorName = streamOutput.sensor_name
            //                            thresholds.thresholdVeryLow = Int32(streamOutput.threshold_very_low)
            //                            thresholds.thresholdLow = Int32(streamOutput.threshold_low)
            //                            thresholds.thresholdMedium = Int32(streamOutput.threshold_medium)
            //                            thresholds.thresholdHigh = Int32(streamOutput.threshold_high)
            //                            thresholds.thresholdVeryHigh = Int32(streamOutput.threshold_very_high)
    
            for measurement in streamOutput.measurements {
                let newMeasaurement: Measurement = self.context.newOrExisting(id: measurement.id)
                
                newMeasaurement.value = Double(measurement.measured_value)
                newMeasaurement.latitude = Double(measurement.latitude)
                newMeasaurement.longitude = Double(measurement.longitude)
                newMeasaurement.time = dateFormatter.date(from: measurement.time)
                newMeasaurement.measurementStream = stream
            }
            session.addToMeasurementStreams(stream)
        }
    
    }
}


