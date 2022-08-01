// Created by Lunar on 10/06/2021.
//

import XCTest
import Combine
import CoreLocation
import Resolver
@testable import AirCasting

final class SynchronizationControllerTests: ACTestCase {
    private var cancellables: [AnyCancellable] = []
    var remoteContextProvider = SynchronizationContextProviderMock()
    var downloadService = DownloadServiceMock()
    var uploadService = UploadServiceMock()
    var store = SessionStoreMock()
    var errorStream = SessionSynchronizerErrorStreamSpy()
    lazy var controller = SessionSynchronizationController()
    
    override func setUp() {
        super.setUp()
        Resolver.test.register { self.remoteContextProvider as SessionSynchronizationContextProvidable }
        Resolver.test.register { self.downloadService as SessionDownstream }
        Resolver.test.register { self.uploadService as SessionUpstream }
        Resolver.test.register { self.store as SessionSynchronizationStore }
        controller.errorStream = errorStream
    }
    
    override func tearDown() {
        super.tearDown()
        cancellables = []
    }
    
    // MARK: - Success path tests
    
    func test_whenTriggered_fetchesLocalDataAndUsesItToAskForSyncContext() {
        let stubbedlocalData: [SessionsSynchronization.Metadata] = [.init(uuid: .random, deleted: false, version: 0),
                                                                    .init(uuid: .random, deleted: true, version: 1)]
        store.localSessionsToReturn = .success(stubbedlocalData)
        
        let localSessionsReceived = spySyncContextRequest()
        assertContainsSameElements(localSessionsReceived, stubbedlocalData)
    }
    
    func test_whenSyncContextReceived_downloadsNewSessions() {
        let newSessionUUIDs: [SessionUUID] = .init(creating: .random, times: 10)
        setupWithPassthruDownloads(downloadUUIDs: newSessionUUIDs)
        
        let requests = spyDownloadRequest(count: 10)
        assertContainsSameElements(requests, newSessionUUIDs)
    }
    
    func test_whenNewSessionsAreDownloaded_savesThemToDataStore() {
        let newSessionUUIDs: [SessionUUID] = .init(creating: .random, times: 10)
        setupWithPassthruDownloads(downloadUUIDs: newSessionUUIDs)
        
        let writtenSessions = spyStoreSaves()
        assertContainsSameElements(writtenSessions.uuids, newSessionUUIDs)
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
        assertContainsSameElements(store.recordedHistory.allReads, uploadUUIDs.map { SessionStoreMock.HistoryItem.readSession($0) })
    }
    
    func test_whenSyncContextReceived_withSessionsToUpload_sendsCorrectDataToService() {
        setupWithStubbingStoreReads([.mock(uuid: "1"), .mock(uuid: "2")])
        let uploads = spyUploadRequest(count: 2)
        assertContainsSameElements(uploads.map { $0.uuid }, ["1", "2"])
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
        XCTAssertEqual(upload.streams, ["Phone Microphone":
                                                .init(sensorName: "Phone Microphone",
                                                      sensorPackageName: "Builtin",
                                                      unitName: "decibels",
                                                      measurementType: "Sound Level",
                                                      measurementShortType: "dB",
                                                      unitSymbol: "dB",
                                                      thresholdVeryLow: 20,
                                                      thresholdLow: 60,
                                                      thresholdMedium: 70,
                                                      thresholdHigh: 80,
                                                      thresholdVeryHigh: 100,
                                                      deleted: false,
                                                      measurements: [
                                                        .init(value: 12.02,
                                                              milliseconds: 0,
                                                              latitude: 51.04,
                                                              longitude: 50.12,
                                                              time: Date(timeIntervalSinceReferenceDate: 150))
                                                      ])
                                       ])
    }
    
    func test_whenSyncContextReceived_withSessionsToRemove_asksStoreToRemove() {
        let sessionsToDelete = [SessionUUID](creating: .random, times: 10)
        setupWithSessionsToDelete(sessionsToDelete)
        let removedSessions = spyStoreRemove()
        assertContainsSameElements(removedSessions, sessionsToDelete)
    }
    
    func test_whenSessionIsUploaded_savesURLLocationToDatabase() {
        let urlsToReturn = ["A", "B"]
        setupUploadWithStubbedSessionLocations(urlsToReturn)
        let savedURLs = spyStoreURLUpdates(count: urlsToReturn.count)
        assertContainsSameElements(urlsToReturn, savedURLs)
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
        let failureUUID: SessionUUID = .random
        simulateDownloadFailure(totalDownloads: 10, errorousDownloadIndex: 4, errorousUUID: failureUUID)
        XCTAssertEqual(store.recordedHistory.allWrittenUUIDs.count, 9)
    }
    
    func test_whenAnyStoreReadFails_itUploadsTheRestAnyway() {
        let failureUUID: SessionUUID = .random
        simulateReadFailure(totalUploads: 10, errorousReadIndex: 7, errorousUUID: failureUUID)
        XCTAssertEqual(uploadService.recordedHistory.count, 9)
    }
    
    // MARK: - Error stream
    
    func test_whenErrorFetchingLocalData_itProducesCorrectErrorStreamEntry() {
        store.localSessionsToReturn = .failure(DummyError())
        controller.triggerSynchronization()
        XCTAssertEqual(errorStream.allErrors, [.cannotFetchLocalData])
    }
    
    func test_whenErrorFetchingSyncContext_itProducesCorrectErrorStreamEntry() {
        remoteContextProvider.toReturn = .failure(DummyError())
        controller.triggerSynchronization()
        XCTAssertEqual(errorStream.allErrors, [.cannotFetchSyncContext])
    }
    
    func test_whenAnyDownloadFails_itProducesCorrectErrorStreamEntry() {
        let failureUUID: SessionUUID = .random
        simulateDownloadFailure(totalDownloads: 10, errorousDownloadIndex: 4, errorousUUID: failureUUID)
        XCTAssertEqual(errorStream.allErrors, [.downloadFailed(failureUUID)])
    }
    
    func test_whenAnyStoreReadFails_itProducesCorrectErrorStreamEntry() {
        let failureUUID: SessionUUID = .random
        simulateReadFailure(totalUploads: 10, errorousReadIndex: 7, errorousUUID: failureUUID)
        XCTAssertEqual(errorStream.allErrors, [.storeReadFailure(failureUUID)])
    }
    
    func test_whenUploadFails_itProducesCorrectErrorStreamEntry() {
        let failureUUID: SessionUUID = .random
        simulateUploadFailure(totalUploads: 10, errorousUploadIndex: 4, errorousUUID: failureUUID)
        XCTAssertEqual(errorStream.allErrors, [.uploadFailure(failureUUID)])
    }
    
    func test_whenStoreWriteFails_itProducesCorrectErrorStreamEntry() {
        let failureUUIDs = [SessionUUID].init(creating: .random, times: 10)
        simulateWriteFailure(uuidsToDownload: failureUUIDs)
        XCTAssertEqual(errorStream.allErrors.count, 1)
        switch errorStream.allErrors[0] {
        case .storeWriteFailure(let uuids): assertContainsSameElements(uuids, failureUUIDs)
        default: XCTFail("Unexpected error!")
        }
    }
    
    func test_whenErrorFetchingSyncContext_andNoInternet_itProducesCorrectErrorStreamEntry() {
        remoteContextProvider.toReturn = .failure(URLError(.notConnectedToInternet))
        controller.triggerSynchronization()
        XCTAssertEqual(errorStream.allErrors, [.noConnection])
    }
    
    func test_whenDownloadingSessions_andNoInternet_itProducesCorrectErrorStreamEntry() {
        simulateBreakingDownloadFailure(firstDownload: 87, error: URLError(.notConnectedToInternet))
        XCTAssertEqual(errorStream.allErrors, [.noConnection])
    }
    
    //
    // Regression: "milliseconds" in uploaded measurements should be actual measurement date milliseconds
    // takeen in `SSS` format, but excluding the most significant digit.
    //
    // e.g. for a measurement taken at 2021-04-10T20:19:21.543Z
    // the "milliseconds" property should be 43.
    //
    func test_whenSendingMeasurements_milliseconsAreSetCorrectly() throws {
        // Set the time to exactly 08.07.2014 20:00.000 UTC
        var measurementDate = Date(timeIntervalSince1970: 1404849600)
        // Add some (420) milliseconds to it
        measurementDate.addTimeInterval(0.420)
        setupWithStubbingStoreReads([.mock(measurementTime: measurementDate)])
        let uploadedData = try XCTUnwrap(spyUploadRequest().first)
        let stream = try XCTUnwrap(uploadedData.streams["Phone Microphone"])
        let measurement = try XCTUnwrap(stream.measurements.first)
        XCTAssertEqual(measurement.milliseconds, 20)
    }
}
