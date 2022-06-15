// Created by Lunar on 16/06/2021.
//

import Foundation

/// Provides conversion functions between various sessions sync data structures
struct SynchronizationDataConverter {
    func convertDownloadToSession(_ download: SessionsSynchronization.SessionDownstreamData) -> SessionsSynchronization.SessionStoreSessionData {
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
                unitSymbol: stream.unitSymbol,
                deleted: false,
                // Backend will not send us measurements, need to sync downstream other way:
                measurements: []
            )
         }
        let notes = download.notes.map { note in
            SessionsSynchronization.SessionStoreNotesData(
                date: note.date,
                text: note.text,
                latitude: note.latitude,
                longitude: note.longitude,
                number: note.number)
        }
        return .init(uuid: download.uuid,
                     contribute: download.contribute,
                     endTime: download.endTime,
                     gotDeleted: false,
                     isIndoor: download.isIndoor ?? false,
                     name: download.title,
                     startTime: download.startTime,
                     tags: download.tagList,
                     urlLocation: download.location?.absoluteString,
                     version: download.version,
                     longitude: download.longitude,
                     latitude: download.latitude,
                     sessionType: download.type,
                     measurementStreams: measurements,
                     deleted: false,
                     notes: notes,
                     notesPhotos: [])
    }
    
    func convertSessionToUploadData(_ session: SessionsSynchronization.SessionStoreSessionData) -> SessionsSynchronization.SessionWithPhotosUpstreamData {
        return .init(session: .init(uuid: session.uuid,
                                    type: session.sessionType,
                                    title: session.name,
                                    notes: convertDatabaseNotesToMetadata(session.notes).sorted(by: { $0.number < $1.number }),
                                    tagList: session.tags ?? "",
                                    startTime: session.startTime,
                                    endTime: session.endTime,
                                    contribute: session.contribute,
                                    isIndoor: session.isIndoor,
                                    version: session.version,
                                    // NOTE: This is not being sent from Android app too and any attempt to put data here
                                    // is causing a 500 Server Error, so it's probably how it should work.
                                    streams: convertDatabaseStreamsToUploadData(session),
                                    latitude: session.latitude,
                                    longitude: session.longitude,
                                    deleted: session.gotDeleted),
                     photos: session.notesPhotos)
    }
    
    func convertDatabaseNotesToMetadata(_ notes: [SessionsSynchronization.SessionStoreNotesData]) -> [SessionsSynchronization.NoteUpstreamData] {
        notes.map { note in
            SessionsSynchronization.NoteUpstreamData(date: note.date,
                                                     text: note.text,
                                                     latitude: note.latitude,
                                                     longitude: note.longitude,
                                                     number: note.number)
        }
    }
    
    func convertDatabaseSessionToMetadata(_ entity: Database.Session) -> SessionsSynchronization.Metadata {
        .init(uuid: entity.uuid, deleted: entity.gotDeleted, version: entity.version)
    }
    
    func convertDatabaseStreamsToUploadData(_ entity: SessionsSynchronization.SessionStoreSessionData) -> [SensorName : SessionsSynchronization.MeasurementStreamUpstreamData] {
        var result = [SensorName : SessionsSynchronization.MeasurementStreamUpstreamData]()
        entity.measurementStreams.forEach {
            result[$0.sensorName] = SessionsSynchronization.MeasurementStreamUpstreamData(sensorName: $0.sensorName,
                                                                                       sensorPackageName: $0.sensorPackageName,
                                                                                       unitName: $0.unitName,
                                                                                       measurementType: $0.measurementType,
                                                                                       measurementShortType: $0.measurementShortType,
                                                                                       unitSymbol: $0.unitSymbol,
                                                                                       thresholdVeryLow: $0.thresholdVeryLow,
                                                                                       thresholdLow: $0.thresholdLow,
                                                                                       thresholdMedium: $0.thresholdMedium,
                                                                                       thresholdHigh: $0.thresholdHigh,
                                                                                       thresholdVeryHigh: $0.thresholdVeryHigh,
                                                                                       deleted: $0.deleted,
                                                                                       measurements: convertDatabaseMeasuremnetsToUploadData($0.measurements))
        }
        return result
    }
    
    func convertDatabaseMeasuremnetsToUploadData(_ measurements: [SessionsSynchronization.SessionStoreMeasurementData]) -> [SessionsSynchronization.MeasurementUpstreamData] {
        measurements.map {
            SessionsSynchronization.MeasurementUpstreamData(value: $0.value, milliseconds:$0.time.milliseconds, latitude: $0.latitude, longitude: $0.longitude, time: $0.time)
        }
    }
    
    func convertDatabaseSessionToSessionStoreData(_ entity: Database.Session) -> SessionsSynchronization.SessionStoreSessionData {
        let measurements = entity.measurementStreams?.map { stream -> SessionsSynchronization.SessionStoreMeasurementStreamData in
            // TODO: Are those force unwraps safe here?
            return SessionsSynchronization.SessionStoreMeasurementStreamData(id: stream.id!,
                                                                             measurementShortType: stream.measurementShortType!,
                                                                             measurementType: stream.measurementType!,
                                                                             sensorName: stream.sensorName!,
                                                                             sensorPackageName: stream.sensorPackageName!,
                                                                             thresholdHigh: Int(stream.thresholdHigh),
                                                                             thresholdLow: Int(stream.thresholdLow),
                                                                             thresholdMedium: Int(stream.thresholdMedium),
                                                                             thresholdVeryHigh: Int(stream.thresholdVeryHigh),
                                                                             thresholdVeryLow: Int(stream.thresholdVeryLow),
                                                                             unitName: stream.unitName!,
                                                                             unitSymbol: stream.unitSymbol!,
                                                                             deleted: stream.deleted,
                                                                             measurements: stream.measurements.map {
                                                                                SessionsSynchronization.SessionStoreMeasurementData(id: $0.id,
                                                                                                                                    time: $0.time,
                                                                                                                                    value: $0.value,
                                                                                                                                    latitude: $0.latitude,
                                                                                                                                    longitude: $0.longitude)
                                                                             })
        }
        
        let notes = entity.notes?.map { note -> SessionsSynchronization.SessionStoreNotesData in
            return .init(date: note.date,
                         text: note.text,
                         latitude: note.latitude,
                         longitude: note.longitude,
                         number: note.number)
        }
        
        return SessionsSynchronization.SessionStoreSessionData(uuid: entity.uuid,
                                                               contribute: entity.contribute,
                                                               endTime: entity.endTime,
                                                               gotDeleted: entity.gotDeleted,
                                                               isIndoor: entity.isIndoor,
                                                               name: entity.name!,
                                                               startTime: entity.startTime!,
                                                               tags: entity.tags,
                                                               urlLocation: entity.urlLocation,
                                                               version: entity.version,
                                                               longitude: entity.location?.longitude,
                                                               latitude: entity.location?.latitude,
                                                               sessionType: entity.type.rawValue,
                                                               measurementStreams: measurements ?? [],
                                                               deleted: entity.gotDeleted,
                                                               notes: notes ?? [],
                                                               notesPhotos: entity.notes?.map({ $0.originalPictureData}) ?? [])
    }
    
    func convertDownloadDataToDatabaseStream(data: SessionsSynchronization.MeasurementStreamDownstreamData) -> SessionsSynchronization.SessionStoreMeasurementStreamData {
        let measurements: [SessionsSynchronization.SessionStoreMeasurementData] = data.measurements?.map { measurement in
            #warning("Remove id from measurement")
            return SessionsSynchronization.SessionStoreMeasurementData(id: .random(in: 0...Int64.max), time: measurement.time, value: measurement.value, latitude: measurement.latitude, longitude: measurement.longitude)
        } ?? []
        return SessionsSynchronization.SessionStoreMeasurementStreamData(id: data.id, measurementShortType: data.measurementShortType, measurementType: data.measurementType, sensorName: data.sensorName, sensorPackageName: data.sensorPackageName, thresholdHigh: data.thresholdHigh, thresholdLow: data.thresholdLow, thresholdMedium: data.thresholdMedium, thresholdVeryHigh: data.thresholdVeryHigh, thresholdVeryLow: data.thresholdVeryLow, unitName: data.unitName, unitSymbol: data.unitSymbol, deleted: false, measurements: measurements)
    }
}
