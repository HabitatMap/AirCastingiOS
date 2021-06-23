// Created by Lunar on 16/06/2021.
//

import Foundation

/// Provides conversion functions between various sessions sync data structures
struct SynchronizationDataConterter {
    @available(*, unavailable, message: "This struct is not meant to be instantiated. It only provides static functions")
    private init() { }
    
    static func convertDownloadToSession(_ download: SessionsSynchronization.SessionDownstreamData) -> SessionsSynchronization.SessionStoreSessionData {
        let measurements = download.streams.values.map { stream in
            SessionsSynchronization.SessionStoreMeasurementStreamData(
                id: MeasurementStreamID(stream.id),
                measurementShortType: stream.measurementShortType,
                measurementType: stream.measurementType,
                sensorName: stream.sensorName,
                sensorPackageName: stream.sensorPackageName,
                thresholdHigh: stream.thresholdHigh,
                thresholdLow: stream.thresholdLow,
                thresholdMedium: stream.thresholdMedium,
                thresholdVeryHigh: stream.thresholdVeryHigh,
                thresholdVeryLow: stream.thresholdVeryLow,
                unitName: stream.unitName,
                unitSymbol: stream.unitSymbol
            )
         }
        return .init(uuid: download.uuid,
                     contribute: download.contribute,
                     endTime: download.endTime,
                     gotDeleted: false,
                     isIndoor: download.isIndoor,
                     name: download.title,
                     startTime: download.startTime,
                     tags: download.tagList,
                     urlLocation: download.location?.absoluteString,
                     version: download.version,
                     longitude: download.longitude,
                     latitude: download.latitude,
                     sessionType: download.type,
                     measurementStreams: measurements)
    }
    
    static func convertSessionToUploadData(_ session: SessionsSynchronization.SessionStoreSessionData) -> SessionsSynchronization.SessionUpstreamData {
        return .init(uuid: session.uuid,
                     type: session.sessionType,
                     title: session.name,
                     // TODO: Notes implementation in the future would require this to be synced
                     notes: [],
                     tagList: session.tags ?? "",
                     startTime: session.startTime,
                     endTime: session.endTime,
                     contribute: session.contribute,
                     isIndoor: session.isIndoor,
                     version: session.version,
                     // NOTE: This is not being sent from Android app too and any attempt to put data here
                     // is causing a 500 Server Error, so it's probably how it should work.
                     streams: [:],
                     latitude: session.latitude,
                     longitude: session.longitude,
                     deleted: session.gotDeleted)
    }
}
