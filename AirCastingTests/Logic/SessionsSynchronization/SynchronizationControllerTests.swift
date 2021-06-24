// Created by Lunar on 10/06/2021.
//

import XCTest
import Combine
import CoreLocation
@testable import AirCasting

class SynchronizationControllerTests: XCTestCase {
    var cancellables: [AnyCancellable] = []
    var remoteContextProvider = SynchronizationContextProviderMock()
    var downloadService = DownloadServiceMock()
    var uploadService = UploadServiceMock()
    var store = SessionStoreMock()
    lazy var controller = SessionSynchronizationController(synchronizationContextProvider: remoteContextProvider,
                                                           downstream: downloadService,
                                                           upstream: uploadService,
                                                           store: store)
    
    // MARK: - Success path tests
    
    func test_whenTriggered_fetchesLocalDataAndUsesItToAskForSyncContext() {
        let stubbedlocalData: [SessionsSynchronization.Metadata] = [.init(uuid: .random, deleted: false, version: 0),
                                                                    .init(uuid: .random, deleted: true, version: 1)]
        store.localSessionsToReturn = .success(stubbedlocalData)
        
        let localSessionsReceived = spySyncContextRequest()
        XCTAssertTrue(localSessionsReceived ~~ stubbedlocalData)
    }
    
    func test_whenSyncContextReceived_downloadsNewSessions() {
        let newSessionUUIDs: [SessionUUID] = .init(creating: .random, times: 10)
        setupWithPassthruDownloads(downloadUUIDs: newSessionUUIDs)
        
        let requests = spyDownloadRequest(count: 10)
        XCTAssertTrue(requests ~~ newSessionUUIDs)
    }
    
    func test_whenNewSessionsAreDownloaded_savesThemToDataStore() {
        let newSessionUUIDs: [SessionUUID] = .init(creating: .random, times: 10)
        setupWithPassthruDownloads(downloadUUIDs: newSessionUUIDs)
        
        let writtenSessions = spyStoreSaves()
        XCTAssertTrue(writtenSessions.uuids ~~ newSessionUUIDs)
    }
    
    func test_whenNewSessionsAreDownloaded_theyAreBeingCorrectlyTranslatedToStoreWriteSessions() {
        let downloadedSession = SessionsSynchronization.SessionDownstreamData.mock()
        setupWithStubbingDownload(downloadedSession)
        
        let writtenSessions = spyStoreSaves()
        XCTAssertEqual(writtenSessions.count, 1)
        XCTAssertEqual(writtenSessions.first!.uuid, downloadedSession.uuid)
        XCTAssertEqual(writtenSessions.first!.contribute, downloadedSession.contribute)
        XCTAssertEqual(writtenSessions.first!.endTime, downloadedSession.endTime)
        XCTAssertEqual(writtenSessions.first!.gotDeleted, false)
        XCTAssertEqual(writtenSessions.first!.isIndoor, downloadedSession.isIndoor)
        XCTAssertEqual(writtenSessions.first!.latitude!, downloadedSession.latitude!, accuracy: 0.1)
        XCTAssertEqual(writtenSessions.first!.longitude!, downloadedSession.longitude!, accuracy: 0.1)
    }
    
    func test_whenSyncContextReceived_withSessionsToUpload_readsDataFromStore() {
        let uploadUUIDs = [SessionUUID](creating: .random, times: 10)
        setupWithPassthruUploads(uploadUUIDs: uploadUUIDs)
        _ = spyUploadRequest(count: 10)
        XCTAssertTrue(store.recordedHistory.allReads ~~ uploadUUIDs.map { SessionStoreMock.HistoryItem.readSession($0) })
    }
    
    func test_whenSyncContextReceived_withSessionsToUpload_sendsCorrectDataToService() {
        setupWithStubbingStoreReads([.mock(uuid: "1"), .mock(uuid: "2")])
        let uploads = spyUploadRequest(count: 2)
        XCTAssertTrue(uploads.map { $0.uuid } ~~ ["1", "2"])
    }
    
    func test_whenSyncContextReceived_withSessionsToUpload_translatesSessionsFromStoreDataToUploadData() {
        setupWithStubbingStoreReads([.mock()])
        let upload = spyUploadRequest().first!
        XCTAssertEqual(upload.uuid, "1234-5678")
        XCTAssertEqual(upload.contribute, true)
        XCTAssertEqual(upload.endTime, .distantFuture)
        XCTAssertEqual(upload.deleted, false)
        XCTAssertEqual(upload.isIndoor, false)
        XCTAssertEqual(upload.title, "Coolio")
        XCTAssertEqual(upload.startTime, .distantPast)
        XCTAssertEqual(upload.tagList, "NOTAG")
        XCTAssertEqual(upload.version, 1)
        XCTAssertEqual(upload.longitude!, 51.0, accuracy: 0.1)
        XCTAssertEqual(upload.latitude!, 51.0, accuracy: 0.1)
        XCTAssertEqual(upload.type, SessionType.mobile.rawValue)
        // See implementation file for notes on that:
        XCTAssertEqual(upload.streams, [:])
    }
    
    func test_whenSyncContextReceived_withSessionsToRemove_asksStoreToRemove() {
        let sessionsToDelete = [SessionUUID](creating: .random, times: 10)
        setupWithSessionsToDelete(sessionsToDelete)
        let removedSessions = spyStoreRemove()
        XCTAssertTrue(removedSessions ~~ sessionsToDelete)
    }
    
    // MARK: - Error handling
    
    func test_whenErrorFetchingLocalData_itDoesNotProcessFuther() {
        store.localSessionsToReturn = .failure(DummyError())
        controller.triggerSynchronization()
        XCTAssertEqual(remoteContextProvider.recordedHistory, [])
    }
    
    func test_whenErrorFetchingSyncContext_itDoesnNotProcessFurther() {
        remoteContextProvider.toReturn = .failure(DummyError())
        controller.triggerSynchronization()
        XCTAssertEqual(downloadService.recordedHistory, [])
        XCTAssertEqual(uploadService.recordedHistory, [])
        XCTAssertEqual(store.recordedHistory.allDeletes, [])
    }
    
    func test_whenAnyDownloadFails_itSavesTheRestToDataStore() {
        simulateDownloadFailure(totalDownloads: 10, errorousDownloadIndex: 4)
        XCTAssertEqual(store.recordedHistory.allWrittenUUIDs.count, 9)
    }
    
    func test_whenAnyStoreReadFails_itUploadsTheRestAnyway() {
        simulateReadFailure(totalUploads: 10, errorousReadIndex: 7)
        XCTAssertEqual(uploadService.recordedHistory.count, 9)
    }
}
