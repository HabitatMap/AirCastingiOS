// Created by Lunar on 21/06/2021.
//

import Foundation
import Combine
import CoreLocation

final class SessionSynchronizationDatabase: SessionSynchronizationStore {
    typealias DatabaseType = SessionsFetchable & SessionRemovable & SessionInsertable
    private enum SessionSynchronizationDatabaseError: Error, LocalizedError {
        case sessionNotFound
        
        var errorDescription: String? {
            switch self {
            case .sessionNotFound: return "Requested session was not found in database"
            }
        }
    }
    
    private let database: DatabaseType
    
    init(database: DatabaseType) {
        self.database = database
    }
    
    func getLocalSessionList() -> AnyPublisher<[SessionsSynchronization.Metadata], Error> {
        Future { promise in
            self.database.fetchSessions(constrained: .all) { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let sessions):
                    promise(.success(sessions.map(SessionsSynchronization.Metadata.init(entity:))))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func addSessions(with sessionsData: [SessionsSynchronization.SessionStoreSessionData]) -> Future<Void, Error> {
        return .init { promise in
            self.database
                .insertSessions(sessionsData.map {
                    let streams = $0.measurementStreams.map {
                        Database.MeasurementStream(id: MeasurementStreamID($0.id),
                                                   sensorName: $0.sensorName,
                                                   sensorPackageName: $0.sensorPackageName,
                                                   measurementType: $0.measurementType,
                                                   measurementShortType: $0.measurementShortType,
                                                   unitName: $0.unitName,
                                                   unitSymbol: $0.unitSymbol,
                                                   thresholdVeryHigh: Int32($0.thresholdVeryHigh),
                                                   thresholdHigh: Int32($0.thresholdHigh),
                                                   thresholdMedium: Int32($0.thresholdMedium),
                                                   thresholdLow: Int32($0.thresholdLow),
                                                   thresholdVeryLow: Int32($0.thresholdVeryLow))
                    }
                    return Database.Session(uuid: $0.uuid,
                                            type: .unknown($0.sessionType), // TODO: Is this the way we want it? Is SessionType incorrectly modeling status quo?
                                            name: $0.name,
                                            deviceType: nil,
                                            location: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude),
                                            startTime: $0.startTime,
                                            contribute: $0.contribute,
                                            deviceId: nil,
                                            endTime: $0.endTime,
                                            followedAt: nil,
                                            gotDeleted: $0.gotDeleted,
                                            isIndoor: $0.isIndoor,
                                            tags: $0.tags,
                                            urlLocation: $0.urlLocation,
                                            version: Int16($0.version!), // TODO: Are we safe?
                                            measurementStreams: streams,
                                            status: .FINISHED)
                }, completion: { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                })
        }
    }
    
    public func removeSessions(with uuids: [SessionUUID]) -> Future<Void, Error> {
        Future { promise in
            self.database.removeSessions(where: .predicate(NSPredicate(format: "uuid IN %@", uuids))) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }
    
    public func readSession(with uuid: SessionUUID) -> Future<SessionsSynchronization.SessionStoreSessionData, Error> {
        Future { promise in
            self.database.fetchSessions(constrained: .predicate(NSPredicate(format: "uuid == %@", uuid.rawValue)), completion: { result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let entities):
                    guard let sessionEntity = entities.first else {
                        promise(.failure(SessionSynchronizationDatabaseError.sessionNotFound))
                        return
                    }
                    promise(.success(sessionEntity.toSynchronizationStoreData()))
                }
            })
        }
    }
}

extension Database.Session {
    func toSynchronizationStoreData() -> SessionsSynchronization.SessionStoreSessionData {
        let measurements = measurementStreams?.map { stream -> SessionsSynchronization.SessionStoreMeasurementStreamData in
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
                                                                             unitSymbol: stream.unitSymbol!)
        }
        return SessionsSynchronization.SessionStoreSessionData(uuid: uuid,
                                                               contribute: contribute,
                                                               endTime: endTime,
                                                               gotDeleted: gotDeleted,
                                                               isIndoor: isIndoor,
                                                               name: name!,
                                                               startTime: startTime!,
                                                               tags: tags,
                                                               urlLocation: urlLocation,
                                                               version: Int(version),
                                                               longitude: location?.longitude,
                                                               latitude: location?.latitude,
                                                               sessionType: type.rawValue,
                                                               measurementStreams: measurements ?? [])
    }
}

extension SessionsSynchronization.Metadata {
    init(entity: Database.Session) {
        self.init(uuid: entity.uuid, deleted: entity.gotDeleted, version: Int(entity.version))
    }
}
