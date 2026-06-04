//
//  UpdateSessionParams.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//

import Foundation
import CoreData
import CoreLocation

final class UpdateSessionParamsService {
    enum Error: Swift.Error {
        case missingContext(Any)
    }

    func updateSessionsParams(session: SessionEntity, output: FixedSession.FixedMeasurementOutput) throws {
        Log.info("Updating session params in core data for session: \(session.uuid) [\(session.name ?? "N/A")]")
        // Indoor fixed sessions have `session.time_zone == UTC` on the BE because
        // there is no lat/lng for it to derive a zone from. The BE serializer
        // still tags the wall-clock numerals with a trailing "Z", so iOS parses
        // them as real UTC. The rest of the app stores Dates with the
        // fakeUTCDate convention (wall-clock numerals as a UTC moment in the
        // phone's TZ), so indoor times must be shifted from real-UTC to the
        // user's local wall clock before persisting.
        let isIndoor = session.isIndoor || (output.is_indoor ?? false)
        session.uuid = output.uuid
        session.type = output.type
        session.name = output.title
        session.tags  = output.tag_list
        session.startTime = output.start_time.shiftedForFixedSession(isIndoor: isIndoor)
        session.endTime = output.end_time.shiftedForFixedSession(isIndoor: isIndoor)
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
            
            let existingThreshold: SensorThreshold? = try context.existingObject(sensorName: streamOutput.sensor_name)
            if existingThreshold == nil {
                let threshold: SensorThreshold = try context.newOrExisting(sensorName: streamOutput.sensor_name)
                threshold.thresholdVeryLow = streamOutput.threshold_very_low
                threshold.thresholdLow = streamOutput.threshold_low
                threshold.thresholdMedium = streamOutput.threshold_medium
                threshold.thresholdHigh = streamOutput.threshold_high
                threshold.thresholdVeryHigh = streamOutput.threshold_very_high
            }

            let oldMeasurements = oldStream.measurements?.array as? [MeasurementEntity] ?? []
            let measurementDiff = diff(oldMeasurements, streamOutput.measurements) {
                return $0.time == $1.time.shiftedForFixedSession(isIndoor: isIndoor) && $0.value == Double($1.value)
            }
            measurementDiff.inserted.forEach {
                let newMeasurement = MeasurementEntity(context: context)
                fillMeasurement(newMeasurement, with: $0, isIndoor: isIndoor)
                newMeasurement.measurementStream = oldStream
            }

            measurementDiff.common.forEach { oldMeasurement, measurementOutput in
                oldMeasurement.value = Double(measurementOutput.value)
                oldMeasurement.location = CLLocationCoordinate2D(latitude: measurementOutput.latitude, longitude: measurementOutput.longitude)
                oldMeasurement.time = measurementOutput.time.shiftedForFixedSession(isIndoor: isIndoor)
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
        entity.locationless = session.locationless
        entity.deviceId = session.deviceId
        entity.endTime = session.endTime
        entity.followedAt = session.followedAt
        entity.gotDeleted = session.gotDeleted
        entity.isIndoor = session.isIndoor
        entity.tags = session.tags
        entity.urlLocation = session.urlLocation
        entity.version = session.version
        entity.status = session.status
        // 0 = "unknown / legacy" — interpreted as 1s native by the averaging gate.
        entity.measurementInterval = session.measurementInterval ?? 0
    }
}

private extension UpdateSessionParamsService {
    func fillMeasurement(_ entity: MeasurementEntity, with measurement: FixedSession.MeasurementOutput, isIndoor: Bool = false) {
        entity.value = Double(measurement.value)
        entity.location = CLLocationCoordinate2D(latitude: measurement.latitude, longitude: measurement.longitude)
        entity.time = measurement.time.shiftedForFixedSession(isIndoor: isIndoor)
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
