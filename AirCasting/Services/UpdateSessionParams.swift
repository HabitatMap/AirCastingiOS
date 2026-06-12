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
        // BE persists fixed-session `Session#start_time`, `Session#end_time`,
        // and `Measurement#time` via `Utils.to_local_as_utc(epoch,
        // session.time_zone)` on V2 ingest. The wall clock is the session's
        // `time_zone` column:
        //   - Indoor sessions: BE defaults `time_zone` to UTC.
        //   - Outdoor sessions WITH lat/lng: BE looks up the geo TZ (≈ phone
        //     TZ in normal use), so the numerals already align with fakeUTC.
        //   - Outdoor sessions WITHOUT a resolvable lat/lng (nil, 0,0,
        //     200,200 sentinels): BE falls back to UTC like indoor.
        //
        // iOS uses the fakeUTC convention (wall-clock numerals as a UTC
        // moment in the phone's TZ). Shift real-UTC numerals (indoor /
        // locationless V2 fixed) to the phone wall clock on persist; leave
        // already-aligned geo-TZ numerals alone.
        //
        // V1 fixed-session timestamps round-trip through BE's
        // `skip_time_zone_conversion_for_attributes` adapter unchanged, so
        // V1 stays at fakeUTC end-to-end and the gate stays false.
        //
        // Previously this site split the gate per timestamp kind under the
        // theory that BE wrote `start_time` as the raw server clock without
        // geo conversion. Empirically (NYC EDT test, local 05:00) the V2
        // outdoor card double-shifted to ~01:00 — BE applies the same
        // `to_local_as_utc` to `start_time` as it does to measurements once
        // geo resolves. Collapse back to a single gate so V2 outdoor
        // start_time / end_time / measurements all stay in BE's geo-TZ
        // numerals untouched, and V2 indoor / locationless all get the UTC
        // → phone-wall-clock shift.
        let shiftFixedTimestamps = Self.sessionRequiresUtcShift(session: session, output: output)
        session.uuid = output.uuid
        session.type = output.type
        session.name = output.title
        session.tags  = output.tag_list
        session.startTime = output.start_time.shiftedForFixedSession(isIndoor: shiftFixedTimestamps)
        session.endTime = output.end_time.shiftedForFixedSession(isIndoor: shiftFixedTimestamps)
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
            try fillStream(stream, with: $0, isIndoor: shiftFixedTimestamps)
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
                return $0.time == $1.time.shiftedForFixedSession(isIndoor: shiftFixedTimestamps) && $0.value == Double($1.value)
            }
            measurementDiff.inserted.forEach {
                let newMeasurement = MeasurementEntity(context: context)
                fillMeasurement(newMeasurement, with: $0, isIndoor: shiftFixedTimestamps)
                newMeasurement.measurementStream = oldStream
            }

            measurementDiff.common.forEach { oldMeasurement, measurementOutput in
                oldMeasurement.value = Double(measurementOutput.value)
                oldMeasurement.location = CLLocationCoordinate2D(latitude: measurementOutput.latitude, longitude: measurementOutput.longitude)
                oldMeasurement.time = measurementOutput.time.shiftedForFixedSession(isIndoor: shiftFixedTimestamps)
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
    /// Returns `true` when BE persists this fixed session's timestamp
    /// numerals in UTC and iOS must shift them back to the phone's wall
    /// clock to match the fakeUTC display convention. Governs
    /// `Session#start_time`, `Session#end_time`, and `Measurement#time`
    /// uniformly: BE writes all three via
    /// `Utils.to_local_as_utc(epoch, session.time_zone)` on V2 ingest.
    /// Indoor / locationless V2 fixed sessions fall back to
    /// `session.time_zone == UTC` and land in those columns as real-UTC
    /// numerals — they need the shift. Outdoor V2 with resolvable coords
    /// uses the geo TZ (≈ phone TZ) and already aligns with fakeUTC, so it
    /// stays as-is — shifting it double-counts the offset (NYC EDT outdoor
    /// session at local 05:00 rendered ~01:00 before this gate was
    /// collapsed back to the indoor / locationless predicate).
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
