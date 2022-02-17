// Created by Lunar on 17/06/2021.
//

import Foundation
import CoreData
import Combine

extension PersistenceController: SessionsFetchable {
    func fetchSessions(constrained: Database.Constraint, completion: @escaping (Result<[Database.Session], Error>) -> Void) {
        let context = self.editContext
        context.perform {
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            if case .predicate(let predicate) = constrained {
                request.predicate = predicate
            }
            do {
                let fetchedEntities = try context.fetch(request)
                let databaseObjects = fetchedEntities.map(Database.Session.init(coreDataEntity:))
                completion(.success(databaseObjects))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

extension PersistenceController: SessionInsertable {
    func insertOrUpdateSessions(_ sessions: [Database.Session], completion: ((Error?) -> Void)?) {
        let context = self.editContext
        context.perform {
            do {
                try sessions.forEach {
                    let sessionEntity: SessionEntity = try context.newOrExisting(uuid: $0.uuid)
                    sessionEntity.uuid = $0.uuid
                    sessionEntity.type = $0.type
                    sessionEntity.name = $0.name
                    sessionEntity.deviceType = $0.deviceType
                    sessionEntity.location = $0.location
                    sessionEntity.startTime = $0.startTime
                    sessionEntity.contribute = $0.contribute
                    sessionEntity.deviceId = $0.deviceId
                    sessionEntity.endTime = $0.endTime
                    sessionEntity.followedAt = $0.followedAt
                    sessionEntity.gotDeleted = $0.gotDeleted
                    sessionEntity.isIndoor = $0.isIndoor
                    sessionEntity.tags = $0.tags
                    sessionEntity.urlLocation = $0.urlLocation
                    sessionEntity.version = Int16($0.version ?? 0)
                    sessionEntity.status = $0.status
                    $0.notes?.forEach {
                        let noteEntity = NoteEntity(context: context)
                        noteEntity.date = $0.date
                        noteEntity.text = $0.text
                        noteEntity.lat = $0.latitude
                        noteEntity.long = $0.longitude
                        noteEntity.number = Int64($0.number)
                        noteEntity.session = sessionEntity
                    }
                    try $0.measurementStreams?.forEach {
                        let streamEntity: MeasurementStreamEntity
                        if let id = $0.id {
                            streamEntity = try context.newOrExisting(streamID: id, for: sessionEntity.uuid)
                        } else {
                            streamEntity = MeasurementStreamEntity(context: context)
                        }
                        streamEntity.id = $0.id
                        streamEntity.measurementShortType = $0.measurementShortType
                        streamEntity.measurementType = $0.measurementType
                        streamEntity.sensorName = $0.sensorName
                        streamEntity.sensorPackageName = $0.sensorPackageName
                        streamEntity.thresholdHigh = Int32($0.thresholdHigh)
                        streamEntity.thresholdLow = Int32($0.thresholdLow)
                        streamEntity.thresholdMedium = Int32($0.thresholdMedium)
                        streamEntity.thresholdVeryHigh = Int32($0.thresholdVeryHigh)
                        streamEntity.thresholdVeryLow = Int32($0.thresholdVeryLow)
                        streamEntity.unitName = $0.unitName
                        streamEntity.unitSymbol = $0.unitSymbol
                        streamEntity.measurements = []
                        streamEntity.session = sessionEntity
                    }
                }
                try context.save()
                completion?(nil)
            } catch {
                completion?(error)
            }
        }
    }
}

extension PersistenceController: SessionRemovable {
    func removeSessions(where constraint: Database.Constraint, completion: ((Error?) -> Void)?) {
        let context = self.editContext
        context.perform {
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            if case .predicate(let predicate) = constraint {
                request.predicate = predicate
            }
            do {
                let fetchedEntities = try context.fetch(request)
                fetchedEntities.forEach(context.delete(_:))
                try context.save()
                completion?(nil)
            } catch {
                completion?(error)
            }
        }
    }
}

extension PersistenceController: SessionUpdateable {
    func updateSessionUrl(_ url: String, for sessionUUID: SessionUUID, completion: ((Error?) -> Void)?) {
        let context = self.editContext
        context.perform {
            do {
                let sessionEntity = try context.existingSession(uuid: sessionUUID)
                sessionEntity.urlLocation = url
                try context.save()
                completion?(nil)
            } catch {
                Log.error("Error adding urlLocation for session: \(error)")
                completion?(error)
            }
        }
    }
}



extension Database.Session {
    init(coreDataEntity: SessionEntity) {
        self.init(uuid: coreDataEntity.uuid,
                  type: coreDataEntity.type,
                  name: coreDataEntity.name,
                  deviceType: coreDataEntity.deviceType,
                  location: coreDataEntity.location,
                  startTime: coreDataEntity.startTime,
                  contribute: coreDataEntity.contribute,
                  deviceId: coreDataEntity.deviceId,
                  endTime: coreDataEntity.endTime,
                  followedAt: coreDataEntity.followedAt,
                  gotDeleted: coreDataEntity.gotDeleted,
                  isIndoor: coreDataEntity.isIndoor,
                  tags: coreDataEntity.tags,
                  urlLocation: coreDataEntity.urlLocation,
                  version: Int(coreDataEntity.version),
                  measurementStreams: (coreDataEntity.measurementStreams?.array as? [MeasurementStreamEntity])?.map(Database.MeasurementStream.init(coreDataEntity:)),
                  status: coreDataEntity.status,
                  notes: (coreDataEntity.notes?.map { note -> Database.Note in
                            let n = note as! NoteEntity
                            return Database.Note(date: n.date ?? DateBuilder.getFakeUTCDate(),
                                                 text: n.text ?? "",
                                                 latitude: n.lat,
                                                 longitude: n.long,
                                                 number: Int(n.number))
                        } ?? [])
        )
    }
}

extension Database.MeasurementStream {
    init(coreDataEntity: MeasurementStreamEntity) {
        self.init(id: coreDataEntity.id,
                  sensorName: coreDataEntity.sensorName,
                  sensorPackageName: coreDataEntity.sensorPackageName,
                  measurementType: coreDataEntity.measurementType,
                  measurementShortType: coreDataEntity.measurementShortType,
                  unitName: coreDataEntity.unitName,
                  unitSymbol: coreDataEntity.unitSymbol,
                  thresholdVeryHigh: Int(coreDataEntity.thresholdVeryHigh),
                  thresholdHigh: Int(coreDataEntity.thresholdHigh),
                  thresholdMedium: Int(coreDataEntity.thresholdMedium),
                  thresholdLow: Int(coreDataEntity.thresholdLow),
                  thresholdVeryLow: Int(coreDataEntity.thresholdVeryLow),
                  measurements: coreDataEntity.allMeasurements?.map {
                    .init(id: $0.id!, time: $0.time, value: $0.value, latitude: $0.location?.latitude, longitude: $0.location?.longitude)
                  } ?? [],
                  deleted: coreDataEntity.gotDeleted)
    }
}

extension Database.Note {
    init(coreDataEntity: NoteEntity) {
        self.init(date: coreDataEntity.date ?? DateBuilder.getFakeUTCDate(),
                  text: coreDataEntity.text ?? "",
                  latitude: coreDataEntity.lat,
                  longitude: coreDataEntity.long,
                  number: Int(coreDataEntity.number))
    }
}
