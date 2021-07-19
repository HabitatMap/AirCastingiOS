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
        case missingContext(Any)
    }

    func updateSessionsParams(session: SessionEntity, output: FixedSession.FixedMeasurementOutput) throws {
        #warning("TODO: set only values that have changed to avoid core data notifications and context changes")
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
        let oldStreams = session.measurementStreams?.array as? [MeasurementStreamEntity] ?? []
        let streamDiff = diff(oldStreams, Array(output.streams.values)) {
            if let id = $0.id {
                return id == $1.id
            } else {
                return false
            }
        }

        try streamDiff.inserted.forEach {
            let stream = MeasurementStreamEntity(context: context)
            try fillStream(stream, with: $0)
            stream.session = session
        }
//        streamDiff.removed.forEach(context.delete)
        try streamDiff.common.forEach { oldStream, streamOutput in
            oldStream.sensorName = streamOutput.sensor_name
            oldStream.sensorPackageName = streamOutput.sensor_package_name
            oldStream.measurementType = streamOutput.measurement_type
            oldStream.measurementShortType = streamOutput.measurement_short_type
            oldStream.unitName = streamOutput.unit_name
            oldStream.unitSymbol = streamOutput.unit_symbol
            oldStream.thresholdVeryLow = streamOutput.threshold_very_low
            oldStream.thresholdLow = streamOutput.threshold_low
            oldStream.thresholdMedium = streamOutput.threshold_medium
            oldStream.thresholdHigh = streamOutput.threshold_high
            oldStream.thresholdVeryHigh = streamOutput.threshold_very_high
            oldStream.gotDeleted = streamOutput.deleted ?? false
            
//            let existingThreshold: SensorThreshold? = try context.existingObject(sensorName: "AirBeam3-PM10")
//            if existingThreshold == nil {
//                let threshold: SensorThreshold = try context.newOrExisting(sensorName: streamOutput.sensor_name)
//                threshold.thresholdVeryLow = streamOutput.threshold_very_low
//                threshold.thresholdLow = streamOutput.threshold_low
//                threshold.thresholdMedium = streamOutput.threshold_medium
//                threshold.thresholdHigh = streamOutput.threshold_high
//                threshold.thresholdVeryHigh = streamOutput.threshold_very_high
//            }
            #warning("MOCKED")
            let thresholdPM10: SensorThreshold = try context.newOrExisting(sensorName: "AirBeam3-PM10")
            thresholdPM10.thresholdVeryLow = 100
            thresholdPM10.thresholdLow = 80
            thresholdPM10.thresholdMedium = 60
            thresholdPM10.thresholdHigh = 20
            thresholdPM10.thresholdVeryHigh = 10

            let thresholdF: SensorThreshold = try context.newOrExisting(sensorName: "AirBeam3-F")
            thresholdF.thresholdVeryLow = 100
            thresholdF.thresholdLow = 80
            thresholdF.thresholdMedium = 60
            thresholdF.thresholdHigh = 20
            thresholdF.thresholdVeryHigh = 10
            
            let thresholdRH: SensorThreshold = try context.newOrExisting(sensorName: "AirBeam3-RH")
            thresholdRH.thresholdVeryLow = 100
            thresholdRH.thresholdLow = 80
            thresholdRH.thresholdMedium = 60
            thresholdRH.thresholdHigh = 20
            thresholdRH.thresholdVeryHigh = 10
            
            let thresholdPM1: SensorThreshold = try context.newOrExisting(sensorName: "AirBeam3-PM1")
            thresholdPM1.thresholdVeryLow = 100
            thresholdPM1.thresholdLow = 80
            thresholdPM1.thresholdMedium = 60
            thresholdPM1.thresholdHigh = 20
            thresholdPM1.thresholdVeryHigh = 10
            
            let thresholdPM2: SensorThreshold = try context.newOrExisting(sensorName: "AirBeam3-PM2.5")
            thresholdPM2.thresholdVeryLow = 100
            thresholdPM2.thresholdLow = 80
            thresholdPM2.thresholdMedium = 60
            thresholdPM2.thresholdHigh = 20
            thresholdPM2.thresholdVeryHigh = 10
            

            let oldMeasurements = oldStream.measurements?.array as? [MeasurementEntity] ?? []
            let measurementDiff = diff(oldMeasurements, streamOutput.measurements) {
                if let id = $0.id {
                    return id == $1.id
                } else {
                    return $0.time == $1.time && $0.value == $1.measured_value
                }
            }
            measurementDiff.inserted.forEach {
                let newMeasurement = MeasurementEntity(context: context)
                fillMeasurement(newMeasurement, with: $0)
                newMeasurement.measurementStream = oldStream
            }
//            measurementDiff.removed.forEach(context.delete)
            measurementDiff.common.forEach { oldMeasurement, measurementOutput in
                oldMeasurement.value = measurementOutput.measured_value
                oldMeasurement.location = CLLocationCoordinate2D(latitude: measurementOutput.latitude, longitude: measurementOutput.longitude)
                oldMeasurement.time = measurementOutput.time
            }
        }
    }

    func updateSessionsParams(_ entity: SessionEntity, session: Session) {
        entity.uuid = session.uuid
        entity.type = session.type
        entity.name = session.name
        entity.deviceType = session.deviceType
        entity.location = session.location
        entity.startTime = session.startTime
        entity.contribute = session.contribute
        entity.deviceId = session.deviceId
        entity.endTime = session.endTime
        entity.followedAt = session.followedAt
        entity.gotDeleted = session.gotDeleted
        entity.isIndoor = session.isIndoor
        entity.tags = session.tags
        entity.urlLocation = session.urlLocation
        entity.version = session.version
        entity.status = session.status
    }
}

private extension UpdateSessionParamsService {
    func fillMeasurement(_ entity: MeasurementEntity, with measurement: FixedSession.MeasurementOutput) {
        entity.value = measurement.measured_value
        entity.location = CLLocationCoordinate2D(latitude: measurement.latitude, longitude: measurement.longitude)
        entity.time = measurement.time
        entity.id = measurement.id
    }

    func fillStream(_ entity: MeasurementStreamEntity, with streamOutput: FixedSession.StreamOutput) throws {
        entity.id = streamOutput.id
        entity.sensorName = streamOutput.sensor_name
        entity.sensorPackageName = streamOutput.sensor_package_name
        entity.measurementType = streamOutput.measurement_type
        entity.measurementShortType = streamOutput.measurement_short_type
        entity.unitName = streamOutput.unit_name
        entity.unitSymbol = streamOutput.unit_symbol
        entity.thresholdVeryLow = streamOutput.threshold_very_low
        entity.thresholdLow = streamOutput.threshold_low
        entity.thresholdMedium = streamOutput.threshold_medium
        entity.thresholdHigh = streamOutput.threshold_high
        entity.thresholdVeryHigh = streamOutput.threshold_very_high
        entity.gotDeleted = streamOutput.deleted ?? false
        guard let context = entity.managedObjectContext else {
            throw Error.missingContext(entity)
        }
        streamOutput.measurements.forEach {
            let newMeasurement = MeasurementEntity(context: context)
            fillMeasurement(newMeasurement, with: $0)
            newMeasurement.measurementStream = entity
        }
    }
}
