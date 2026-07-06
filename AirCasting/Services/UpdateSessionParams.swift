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
        // Now that the app uploads its `time_zone` when creating a V2 fixed
        // session, BE stores that and returns `Session#end_time` and
        // `Measurement#time` via `Utils.to_local_as_utc(epoch,
        // session.time_zone)` in the phone's wall clock — already aligned with
        // iOS's fakeUTC convention, so no shift is applied (`shiftFixedTimestamps`
        // is always false; see `sessionRequiresUtcShift`).
        //
        // `Session#start_time` is the exception: BE sets it itself at session
        // creation from the raw server clock (UTC) and does NOT run it through
        // `to_local_as_utc`, so re-reading it here delivers numerals ~offset
        // behind the wall clock (outdoor V2 card start read 2h behind in a
        // UTC+2 Warsaw test while end_time / measurements were correct).
        // start_time never changes after the session begins, and iOS already
        // stamps the correct wall-clock value locally at creation
        // (`AirBeamFixedWifiSessionCreator` → `getFakeUTCDate()`), so keep the
        // stored value and only fall back to BE's when we have none (defensive;
        // an app-created fixed session always has a local start). Mirrors
        // Android setting start_time once in `SessionDownloadService` and never
        // touching it during measurement refresh.
        let shiftFixedTimestamps = Self.sessionRequiresUtcShift(session: session, output: output)
        session.uuid = output.uuid
        session.type = output.type
        session.name = output.title
        session.tags  = output.tag_list
        if session.startTime == nil {
            session.startTime = output.start_time.shiftedForFixedSession(isIndoor: shiftFixedTimestamps)
        }
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
    /// Whether iOS must UTC-shift this fixed session's downloaded timestamp
    /// numerals to the phone's wall clock. Now always `false`: the app sends
    /// its `time_zone` when creating a V2 fixed session
    /// (`V2FixedSessionAPI.RequestBody.time_zone`), so BE stores that as the
    /// session's `time_zone` and writes `Session#start_time`,
    /// `Session#end_time`, and `Measurement#time` via
    /// `Utils.to_local_as_utc(epoch, session.time_zone)` in the phone's wall
    /// clock. Those numerals already match iOS's fakeUTC display convention
    /// for every app-created fixed session — indoor, locationless, or outdoor
    /// — so no shift is needed; shifting would double-count the offset.
    ///
    /// Before this, BE defaulted `time_zone` to UTC for indoor / locationless
    /// sessions and iOS had to shift those back. Mirrors Android dropping the
    /// `isIndoor && isAirBeamMiniV2` special case once the client began
    /// uploading `time_zone` (dev commit 2b33244aa). Kept as a single gate so
    /// the download cursor and the persist path stay in lockstep.
    ///
    /// External (government / OpenAQ) sessions are not app-created, so we never
    /// upload their `time_zone`; their download path is handled separately in
    /// `DownloadMeasurementsService` and is unaffected.
    static func sessionRequiresUtcShift(session: SessionEntity, output: FixedSession.FixedMeasurementOutput) -> Bool {
        false
    }

    static func sessionRequiresUtcShift(session: SessionEntity) -> Bool {
        false
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
