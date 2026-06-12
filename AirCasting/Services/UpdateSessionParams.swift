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
        // BE persists fixed-session timestamps as wall-clock numerals tagged
        // with a literal "Z", but the wall clock used depends on which BE
        // column wrote the value:
        //
        //   1. `Session#start_time` is set to the production BE's server
        //      clock at session-creation time. It is NEVER run through
        //      `Utils.to_local_as_utc(epoch, session.time_zone)`, so the
        //      stored numerals are real UTC regardless of indoor / outdoor.
        //      Symptom before this guard: V2 outdoor session card displayed
        //      raw-UTC numerals (e.g. "10:00") for sessions started at
        //      12:00 wall clock in a UTC+2 phone TZ.
        //   2. `Session#end_time` and `Measurement#time` are written via
        //      `to_local_as_utc(epoch, session.time_zone)` on every
        //      measurement ingest. The wall clock is the session's
        //      `time_zone` column:
        //        - Indoor sessions: BE defaults `time_zone` to UTC.
        //        - Outdoor sessions WITH lat/lng: BE looks up the geo TZ
        //          (≈ phone TZ in normal use).
        //        - Outdoor sessions WITHOUT a resolvable lat/lng (nil, 0,0,
        //          200,200 sentinels): BE falls back to UTC like indoor.
        //      So those numerals are real UTC for case 2's UTC fallback and
        //      already-phone-aligned otherwise.
        //
        // iOS uses the fakeUTC convention (wall-clock numerals as a UTC
        // moment in the phone's TZ), so any real-UTC numerals BE hands back
        // must be shifted to the phone's local wall clock before persisting.
        //
        // V1 fixed-session timestamps round-trip through BE's
        // `skip_time_zone_conversion_for_attributes` adapter unchanged, so
        // V1 stays at fakeUTC end-to-end and neither flag fires.
        let isV2Fixed = session.deviceFirmwareVersion == .v2
        let shiftStartTime = isV2Fixed
        let shiftEndAndMeasurements = isV2Fixed && Self.sessionRequiresUtcShift(session: session, output: output)
        session.uuid = output.uuid
        session.type = output.type
        session.name = output.title
        session.tags  = output.tag_list
        session.startTime = output.start_time.shiftedForFixedSession(isIndoor: shiftStartTime)
        session.endTime = output.end_time.shiftedForFixedSession(isIndoor: shiftEndAndMeasurements)
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
            try fillStream(stream, with: $0, isIndoor: shiftEndAndMeasurements)
            stream.session = session
        }
        
        try streamDiff.common.forEach { oldStream, streamOutput in
            oldStream.sensorName = streamOutput.sensor_name
            oldStream.sensorPackageName = derivedPackageName(from: streamOutput)
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
                return $0.time == $1.time.shiftedForFixedSession(isIndoor: shiftEndAndMeasurements) && $0.value == Double($1.value)
            }
            measurementDiff.inserted.forEach {
                let newMeasurement = MeasurementEntity(context: context)
                fillMeasurement(newMeasurement, with: $0, isIndoor: shiftEndAndMeasurements)
                newMeasurement.measurementStream = oldStream
            }

            measurementDiff.common.forEach { oldMeasurement, measurementOutput in
                oldMeasurement.value = Double(measurementOutput.value)
                oldMeasurement.location = CLLocationCoordinate2D(latitude: measurementOutput.latitude, longitude: measurementOutput.longitude)
                oldMeasurement.time = measurementOutput.time.shiftedForFixedSession(isIndoor: shiftEndAndMeasurements)
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
    /// Returns `true` when BE persists this fixed session's measurement /
    /// end-time numerals in UTC and iOS must shift them back to the phone's
    /// wall clock to match the fakeUTC display convention.
    ///
    /// Only governs `Measurement#time` and `Session#end_time`, which BE
    /// writes via `Utils.to_local_as_utc(epoch, session.time_zone)` on every
    /// V2 binary measurement ingest. Indoor / locationless V2 fixed sessions
    /// fall back to `session.time_zone == UTC` and land in the column as
    /// real-UTC numerals — those need the shift. Outdoor V2 with resolvable
    /// coords uses the geo TZ (≈ phone TZ) and already aligns with fakeUTC.
    ///
    /// `Session#start_time` is handled separately at the call site because BE
    /// writes it once at session creation in the production server clock
    /// (UTC) without running it through `to_local_as_utc`, so V2 fixed
    /// `start_time` always needs the shift regardless of indoor / outdoor.
    ///
    /// V1 sessions upload gzipped-JSON Dates that BE writes as wall-clock
    /// numerals via `skip_time_zone_conversion_for_attributes` — those
    /// already align with iOS's fakeUTC convention, and shifting double-
    /// counts the offset (V1 indoor in Warsaw rendered 11:00 for a 09:00
    /// wall clock before this guard).
    static func sessionRequiresUtcShift(session: SessionEntity, output: FixedSession.FixedMeasurementOutput) -> Bool {
        guard session.deviceFirmwareVersion == .v2 else { return false }
        if session.isIndoor || (output.is_indoor ?? false) { return true }
        return !sessionHasResolvableLocation(session)
    }

    /// Same predicate as `sessionRequiresUtcShift(session:output:)` but
    /// callable without a downloaded `FixedMeasurementOutput`. Used by the
    /// download cursor (`last_measurement_sync`) where the BE comparison
    /// numerals must match the same UTC vs phone-TZ flavor that gated the
    /// stored timestamps.
    static func sessionRequiresUtcShift(session: SessionEntity) -> Bool {
        guard session.deviceFirmwareVersion == .v2 else { return false }
        if session.isIndoor { return true }
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
    /// Fixed-session streams from the BE carry `sensor_package_name` derived
    /// from the airbeam record's `mac_address`. For V2 Mini sessions the iOS
    /// app has no real BLE MAC available, so the BE ends up storing whatever
    /// MAC-like string the app synthesized (e.g. "BD:F1:54:09:78:1E") — and
    /// `SessionTypeIndicator` splits on `:` / `-` and renders the leading hex
    /// pair as the device label. Recover the model name from `sensor_name`
    /// instead, which the app controls and ships in the canonical
    /// `"{model}-{stream}"` shape ("AirBeamMini-PM1", "AirBeam3-PM1", ...).
    func derivedPackageName(from streamOutput: FixedSession.StreamOutput) -> String {
        if let prefix = streamOutput.sensor_name.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false).first,
           !prefix.isEmpty {
            return String(prefix)
        }
        return streamOutput.sensor_package_name
    }

    func fillMeasurement(_ entity: MeasurementEntity, with measurement: FixedSession.MeasurementOutput, isIndoor: Bool) {
        entity.value = Double(measurement.value)
        entity.location = CLLocationCoordinate2D(latitude: measurement.latitude, longitude: measurement.longitude)
        entity.time = measurement.time.shiftedForFixedSession(isIndoor: isIndoor)
    }

    func fillStream(_ entity: MeasurementStreamEntity, with streamOutput: FixedSession.StreamOutput, isIndoor: Bool) throws {
        entity.id = streamOutput.id
        entity.sensorName = streamOutput.sensor_name
        entity.sensorPackageName = derivedPackageName(from: streamOutput)
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
        // Propagate the caller's shift flag — first-batch measurements on a
        // newly-created stream go through this path, and silently defaulting to
        // `isIndoor: false` here meant V2 indoor / locationless sessions stored
        // their initial measurement batch in raw UTC while the session times
        // were correctly shifted, so the graph plotted the first measurement
        // two hours before the card's start time.
        streamOutput.measurements.forEach {
            let newMeasurement = MeasurementEntity(context: context)
            fillMeasurement(newMeasurement, with: $0, isIndoor: isIndoor)
            newMeasurement.measurementStream = entity
        }
    }
}
