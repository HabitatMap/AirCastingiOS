// Created by Lunar on 14/06/2021.
//

import XCTest
import Combine
import CoreLocation
@testable import AirCasting

// MARK: - External dependencies test doubles

class SynchronizationContextProviderMock: SessionSynchronizationContextProvidable {
    var toReturn: Result<SessionsSynchronization.SynchronizationContext, Error>
    @Published var recordedHistory: [[SessionsSynchronization.Metadata]] = []
    
    init(toReturn: Result<SessionsSynchronization.SynchronizationContext, Error> = .success(.empty)) {
        self.toReturn = toReturn
    }
    
    func getSynchronizationContext(localSessions: [SessionsSynchronization.Metadata]) -> AnyPublisher<SessionsSynchronization.SynchronizationContext, Error> {
        recordedHistory.append(localSessions)
        return Future { promise in
            promise(self.toReturn)
        }.eraseToAnyPublisher()
    }
}

class DownloadServiceMock: SessionDownstream {
    var toReturn: Result<SessionsSynchronization.SessionDownstreamData, Error>?
    @Published var recordedHistory: [SessionUUID] = []
    
    init(toReturn: Result<SessionsSynchronization.SessionDownstreamData, Error>? = nil) {
        self.toReturn = toReturn
    }
    
    func download(session: SessionUUID) -> AnyPublisher<SessionsSynchronization.SessionDownstreamData, Error> {
        recordedHistory.append(session)
        return Future { promise in
            promise(self.toReturn ?? .success(.mock(uuid: session)))
        }.eraseToAnyPublisher()
    }
}

class UploadServiceMock: SessionUpstream {
    var toReturn: Result<Void, Error>?
    @Published var recordedHistory: [SessionsSynchronization.SessionUpstreamData] = []
    
    var allUploadedUUIDs: [SessionUUID] { recordedHistory.map(\.uuid) }
    
    func upload(session: SessionsSynchronization.SessionUpstreamData) -> Future<Void, Error> {
        recordedHistory.append(session)
        return .init { promise in
            promise(self.toReturn ?? .success(()))
        }
    }
}

class SessionStoreMock: SessionSynchronizationStore {
    enum HistoryItem: Equatable {
        case getLocalSessions
        case addSessions([SessionsSynchronization.SessionStoreSessionData])
        case removeSessions([SessionUUID])
        case readSession(SessionUUID)
    }
    
    @Published private(set) var recordedHistory: [HistoryItem] = []
    var writeErrorToReturn: Error? = nil
    var readErrorToReturn: Error? = nil
    var deleteErrorToReturn: Error? = nil
    
    var localSessionsToReturn: Result<[SessionsSynchronization.Metadata], Error> = .success([.random])
    var readSessionToReturn: SessionsSynchronization.SessionStoreSessionData? = nil

    func getLocalSessionList() -> AnyPublisher<[SessionsSynchronization.Metadata], Error> {
        recordedHistory.append(.getLocalSessions)
        return Future { promise in
            promise(self.localSessionsToReturn)
        }.eraseToAnyPublisher()
    }
    
    func addSessions(with sessions: [SessionsSynchronization.SessionStoreSessionData]) -> Future<Void, Error> {
        recordedHistory.append(.addSessions(sessions))
        return .init {
            $0(self.writeErrorToReturn == nil ? .success(()) : .failure(self.writeErrorToReturn!))
        }
    }
    
    func removeSessions(with sessions: [SessionUUID]) -> Future<Void, Error> {
        recordedHistory.append(.removeSessions(sessions))
        return .init {
            $0(self.deleteErrorToReturn == nil ? .success(()) : .failure(self.deleteErrorToReturn!))
        }
    }
    
    func readSession(with uuid: SessionUUID) -> Future<SessionsSynchronization.SessionStoreSessionData, Error> {
        recordedHistory.append(.readSession(uuid))
        return .init {
            $0(self.readErrorToReturn == nil ? .success(self.readSessionToReturn ?? .mock(uuid: uuid.rawValue)) : .failure(self.readErrorToReturn!))
        }
    }
}

// MARK: Mock data structures

extension SessionsSynchronization.SynchronizationContext {
    static var empty: Self { .init(needToBeDownloaded: [], needToBeUploaded: [], removed: []) }
}

extension SessionsSynchronization.SessionDownstreamData {
    static func mock(uuid: SessionUUID = .random, latitude: Double = .default, longitude: Double = .default) -> Self {
        .init(id: .default,
              createdAt: .distantPast,
              updatedAt: .distantPast.advanced(by: 3600),
              userId: .default,
              urlToken: .default,
              type: .default,
              uuid: uuid,
              title: .default,
              tagList: .default,
              startTime: .distantPast,
              endTime: .distantFuture,
              latitude: latitude,
              longitude: longitude,
              contribute: .default,
              version: .default,
              streams: .default,
              location: .default,
              isIndoor: .default)
    }
}

extension SessionsSynchronization.SessionStoreSessionData {
    static func mock(uuid: String = "1234-5678") -> Self {
        .init(uuid: .init(rawValue: uuid)!,
              contribute: true,
              endTime: .distantFuture,
              gotDeleted: false,
              isIndoor: false,
              name: "Coolio",
              startTime: .distantPast,
              tags: "NOTAG",
              urlLocation: "http://www.google.com",
              version: 1,
              longitude: 51.0,
              latitude: 51.0,
              sessionType: SessionType.mobile.rawValue,
              measurementStreams: [
                SessionsSynchronization.SessionStoreMeasurementStreamData(id: 54321,
                                                                               measurementShortType: "dB",
                                                                               measurementType: "Sound Level",
                                                                               sensorName: "Phone Microphone",
                                                                               sensorPackageName: "Builtin",
                                                                               thresholdHigh: 80,
                                                                               thresholdLow: 60,
                                                                               thresholdMedium: 70,
                                                                               thresholdVeryHigh: 100,
                                                                               thresholdVeryLow: 20,
                                                                               unitName: "decibels",
                                                                               unitSymbol: "dB")
              ])
    }
}

extension SessionUUID {
    static var random: SessionUUID {
        return .init(rawValue: UUID().uuidString)!
    }
}

extension SessionsSynchronization.MeasurementStreamDownstreamData: TestDefaultProviding {
    static var `default`: SessionsSynchronization.MeasurementStreamDownstreamData {
        .mock()
    }
}

extension SessionsSynchronization.SessionDownstreamData: TestDefaultProviding {
    static var `default`: SessionsSynchronization.SessionDownstreamData {
        .mock(uuid: .random)
    }
}

extension SessionsSynchronization.SessionStoreSessionData: TestDefaultProviding {
    static var `default`: SessionsSynchronization.SessionStoreSessionData {
        .mock()
    }
}

extension SessionsSynchronization.MeasurementStreamDownstreamData {
    static func mock() -> Self {
        .init(id: 54321,
              sensorName: "Phone Microphone",
              sensorPackageName: "Builtin",
              unitName: "decibels",
              measurementType: "Sound Level",
              measurementShortType: "dB",
              unitSymbol: "dB",
              thresholdVeryLow: 20,
              thresholdLow: 60,
              thresholdMedium: 70,
              thresholdHigh: 80,
              thresholdVeryHigh: 100)
    }
}

// MARK: Conveniance extensions

extension Array where Element == SessionStoreMock.HistoryItem {
    var allReads: [Element] { filter { if case .readSession(_) = $0 { return true }; return false } }
    var allWrites: [Element] { filter { if case .addSessions(_) = $0 { return true }; return false } }
    var allDeletes: [Element] { filter { if case .removeSessions(_) = $0 { return true }; return false } }
    
    var allWrittenData: [SessionsSynchronization.SessionStoreSessionData] {
        allWrites.map { write -> [SessionsSynchronization.SessionStoreSessionData]? in
            guard case .addSessions(let session) = write else { return nil }
            return session
        }
        .compactMap { $0 }
        .flatMap { $0 }
    }
    
    var allWrittenUUIDs: [SessionUUID] { allWrittenData.map(\.uuid) }
    
    var allRemovedUUIDs: [SessionUUID] {
        allDeletes.map { item -> [SessionUUID]? in
            guard case .removeSessions(let uuids) = item else { return nil }
            return uuids
        }
        .compactMap { $0 }
        .flatMap { $0 }
    }
}

extension Array where Element == SessionsSynchronization.SessionStoreSessionData {
    var uuids: [SessionUUID] { map(\.uuid) }
}

extension Array where Element == SessionsSynchronization.SessionUpstreamData {
    var uuids: [SessionUUID] { map(\.uuid) }
}
