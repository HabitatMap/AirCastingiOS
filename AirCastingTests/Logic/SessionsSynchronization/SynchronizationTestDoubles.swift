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
    var toReturn: Result<SessionsSynchronization.SessionUpstreamResult, Error>?
    @Published var recordedHistory: [SessionsSynchronization.SessionUpstreamData] = []
    
    var allUploadedUUIDs: [SessionUUID] { recordedHistory.map(\.uuid) }
    
    func upload(session: SessionsSynchronization.SessionUpstreamData) -> Future<SessionsSynchronization.SessionUpstreamResult, Error> {
        recordedHistory.append(session)
        return .init { promise in
            promise(self.toReturn ?? .success(.init(location: "http://example.com/loc")))
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

class SessionSynchronizerErrorStreamSpy: SessionSynchronizerErrorStream {
    var allErrors: [SessionSynchronizerError] = []
    
    func handleSyncError(_ error: SessionSynchronizerError) {
        allErrors.append(error)
    }
}
