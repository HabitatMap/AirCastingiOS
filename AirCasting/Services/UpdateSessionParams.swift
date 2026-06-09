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
        // BE persists session/measurement timestamps as wall-clock numerals
        // tagged with a literal "Z". The wall clock is the session's
        // `time_zone` column on BE:
        //   - Indoor sessions: BE defaults `time_zone` to UTC.
        //   - Outdoor sessions WITH lat/lng: BE looks up the geo TZ (≈ phone TZ).
        //   - Outdoor sessions WITHOUT a valid lat/lng (nil or 0,0 fallback the
        //     iOS V2 fixed-session POST sends): BE has no coords to look up, so
        //     `time_zone` falls back to UTC just like indoor.
        // iOS uses the fakeUTC convention internally (wall-clock numerals as a
        // UTC moment in the phone's TZ), so the UTC-tagged real-UTC numerals BE
        // returns for those two cases must be shifted to the phone's local
        // wall clock before persisting. Outdoor + valid coords already lines
        // up because BE's geo TZ matches the phone TZ in normal use.
        let beUsesUtc = sessionRequiresUtcShift(session: session, output: output)
        let isIndoor = beUsesUtc
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

extension UpdateSessionParamsService {
    /// Returns `true` when the BE persists this fixed session's wall-clock
    /// numerals in UTC and iOS must shift them back to the phone's wall clock
    /// to match the fakeUTC display convention.
    ///
    /// Only V2 (AirBeam Mini new-firmware) fixed sessions hit this codepath:
    /// V2 binary measurement uploads (`u32` epoch) go through BE's
    /// `Utils.to_local_as_utc(epoch, session.time_zone)` ingest, so indoor /
    /// locationless sessions (BE defaults `session.time_zone` to UTC) land in
    /// the column as real-UTC numerals and need the shift. V1 sessions upload
    /// gzipped-JSON Dates that BE writes as wall-clock numerals via
    /// `skip_time_zone_conversion_for_attributes` — those already align with
    /// iOS's fakeUTC convention, and shifting double-counts the offset (V1
    /// indoor in Warsaw rendered 11:00 for a 09:00 wall clock before this
    /// guard).
    static func sessionRequiresUtcShift(session: SessionEntity, output: FixedSession.FixedMeasurementOutput) -> Bool {
        guard session.deviceFirmwareVersion == .v2 else { return false }
        if session.isIndoor || (output.is_indoor ?? false) { return true }
        return !sessionHasResolvableLocation(session)
    }

    private static func sessionHasResolvableLocation(_ session: SessionEntity) -> Bool {
        guard let coord = session.location else { return false }
        // Treat any sentinel / out-of-range coordinate the app may have stamped
        // onto the session as "no location" — BE can't geo-lookup a TZ from any
        // of these and falls back to UTC just like indoor / nil-location:
        //   - (200, 200): explicit "no location" sentinel set by
        //     `ConfirmCreatingSessionView.getAndSaveStartingLocation` for indoor
        //     and locationless fixed sessions.
        //   - (0, 0): the V1 fixed POST fallback in `AirBeamFixedWifiSessionCreator`
        //     when `session.location` is nil.
        //   - Anything else outside valid lat ∈ [-90, 90] / lon ∈ [-180, 180].
        let bothZero = coord.latitude == 0 && coord.longitude == 0
        let outOfRange = abs(coord.latitude) > 90 || abs(coord.longitude) > 180
        return !(bothZero || outOfRange)
    }

    func sessionRequiresUtcShift(session: SessionEntity, output: FixedSession.FixedMeasurementOutput) -> Bool {
        Self.sessionRequiresUtcShift(session: session, output: output)
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
