// Created by Lunar on 21/06/2021.
//

import Foundation
import Combine
import CoreLocation
import Resolver

final class SessionSynchronizationDatabase: SessionSynchronizationStore {
    private enum SessionSynchronizationDatabaseError: Error, LocalizedError {
        case sessionNotFound
        
        var errorDescription: String? {
            switch self {
            case .sessionNotFound: return "Requested session was not found in database"
            }
        }
    }
    
    @Injected private var sessionsFetcher: SessionsFetchable
    @Injected private var sessionsRemover: SessionRemovable
    @Injected private var sessionsInserter: SessionInsertable
    private let dataConverter = SynchronizationDataConverter()
    
    func getLocalSessionList() -> AnyPublisher<[SessionsSynchronization.Metadata], Error> {
        Future { [sessionsFetcher, dataConverter] promise in
            let predicate = NSPredicate(format: "locationless = %d", false)
            sessionsFetcher.fetchSessions(constrained: .predicate(predicate)) { [dataConverter] result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let sessions):
                    promise(.success(sessions.map(dataConverter.convertDatabaseSessionToMetadata(_:))))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func addSessions(with sessionsData: [SessionsSynchronization.SessionStoreSessionData]) -> Future<Void, Error> {
        return .init { [sessionsInserter] promise in
            sessionsInserter
                .insertOrUpdateSessions(sessionsData.map { sessionData in
                    let streams = sessionData.measurementStreams.map {
                        Database.MeasurementStream(id: MeasurementStreamID($0.id),
                                                   sensorName: $0.sensorName,
                                                   sensorPackageName: $0.sensorPackageName,
                                                   measurementType: $0.measurementType,
                                                   measurementShortType: $0.measurementShortType,
                                                   unitName: $0.unitName,
                                                   unitSymbol: $0.unitSymbol,
                                                   thresholdVeryHigh: $0.thresholdVeryHigh,
                                                   thresholdHigh: $0.thresholdHigh,
                                                   thresholdMedium: $0.thresholdMedium,
                                                   thresholdLow: $0.thresholdLow,
                                                   thresholdVeryLow: $0.thresholdVeryLow,
                                                   measurements: $0.measurements.map {
                                                    .init(id: $0.id, time: $0.time, value: $0.value, latitude: $0.latitude, longitude: $0.longitude)
                                                   },
                                                   deleted: $0.deleted)
                    }
                    let notes = sessionData.notes.map {
                        Database.Note(date: $0.date,
                                      text: $0.text,
                                      latitude: $0.latitude,
                                      longitude: $0.longitude,
                                      number: $0.number)
                    }
                    let location: CLLocationCoordinate2D? = {
                        guard let latitude = sessionData.latitude,
                              let longitude = sessionData.longitude else { return nil }
                        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }()
                    return Database.Session(uuid: sessionData.uuid,
                                            type: .unknown(sessionData.sessionType), // TODO: Is this the way we want it? Is SessionType incorrectly modeling status quo?
                                            name: sessionData.name,
                                            deviceType: nil,
                                            location: location,
                                            startTime: sessionData.startTime,
                                            contribute: sessionData.contribute,
                                            deviceId: nil,
                                            endTime: sessionData.endTime,
                                            followedAt: nil,
                                            gotDeleted: sessionData.gotDeleted,
                                            isIndoor: sessionData.isIndoor,
                                            tags: sessionData.tags,
                                            urlLocation: sessionData.urlLocation,
                                            version: sessionData.version,
                                            measurementStreams: streams,
                                            status: .FINISHED,
                                            notes: notes)
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
        Future { [sessionsRemover] promise in
            sessionsRemover.removeSessions(where: .predicate(NSPredicate(format: "uuid IN %@", uuids))) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
    }
    
    public func readSession(with uuid: SessionUUID) -> Future<SessionsSynchronization.SessionStoreSessionData, Error> {
        Future { [sessionsFetcher, dataConverter] promise in
            sessionsFetcher.fetchSessions(constrained: .predicate(NSPredicate(format: "uuid == %@", uuid.rawValue)), completion: { [dataConverter] result in
                switch result {
                case .failure(let error):
                    promise(.failure(error))
                case .success(let entities):
                    guard let sessionEntity = entities.first else {
                        promise(.failure(SessionSynchronizationDatabaseError.sessionNotFound))
                        return
                    }
                    promise(.success(dataConverter.convertDatabaseSessionToSessionStoreData(sessionEntity)))
                }
            })
        }
    }
}
