// Created by Lunar on 15/06/2021.
//

@testable import AirCasting
import XCTest
import Combine

extension SynchronizationControllerTests {
    
    // MARK: Fixture setups
    
    func setupWithStubbingDownload(_ download: SessionsSynchronization.SessionDownstreamData) {
        let newSessionsUuids = [SessionUUID(rawValue: UUID().uuidString)!]
        let context = SessionsSynchronization.SynchronizationContext(needToBeDownloaded: newSessionsUuids, needToBeUploaded: .empty, removed: .empty)
        remoteContextProvider.toReturn = .success(context)

        downloadService.toReturn = .success(download)
    }
    
    func setupWithStubbingStoreReads(_ stored: [SessionsSynchronization.SessionStoreSessionData]) {
        self.store.readSessionToReturn = stored[0]
        let uuidsToFetch = [SessionUUID?](creating: SessionUUID(rawValue: UUID().uuidString), times: stored.count).compactMap { $0 }
        let context = SessionsSynchronization.SynchronizationContext(needToBeDownloaded: .empty, needToBeUploaded: uuidsToFetch, removed: .empty)
        remoteContextProvider.toReturn = .success(context)
        var sub: AnyCancellable?
        sub = store.$recordedHistory.map { history in
            history.allReads.count
        }.filter { $0 > 0 }
        .sink { numberOfReadsAlreadyDone in
            guard numberOfReadsAlreadyDone <= stored.count else {
                sub?.cancel()
                return
            }
            self.store.readSessionToReturn = stored[numberOfReadsAlreadyDone - 1]
        }
    }
    
    func setupWithPassthruDownloads(downloadUUIDs: [SessionUUID]) {
        let context = SessionsSynchronization.SynchronizationContext(needToBeDownloaded: downloadUUIDs, needToBeUploaded: .empty, removed: .empty)
        remoteContextProvider.toReturn = .success(context)
    }
    
    func setupWithPassthruUploads(uploadUUIDs: [SessionUUID]) {
        let context = SessionsSynchronization.SynchronizationContext(needToBeDownloaded: .empty, needToBeUploaded: uploadUUIDs, removed: .empty)
        remoteContextProvider.toReturn = .success(context)
    }
    
    func setupWithSessionsToDelete(_ UUIDsToRemove: [SessionUUID]) {
        let context = SessionsSynchronization.SynchronizationContext(needToBeDownloaded: .empty, needToBeUploaded: .empty, removed: UUIDsToRemove)
        remoteContextProvider.toReturn = .success(context)
    }
    
    // MARK: Spying
    
    func spySyncContextRequest() -> [SessionsSynchronization.Metadata] {
        return spyOnPublisher(remoteContextProvider.$recordedHistory, count: 1, filter: { $0.count > 0 }).last?.last ?? []
    }
    
    func spyDownloadRequest(count: Int = 1) -> [SessionUUID] {
        return spyOnPublisher(downloadService.$recordedHistory, count: count, filter: { $0.count > 0 }).last ?? []
    }
    
    func spyUploadRequest(count: Int = 1) -> [SessionsSynchronization.SessionUpstreamData] {
        return spyOnPublisher(uploadService.$recordedHistory, count: count, filter: { $0.count > 0 }).last ?? []
    }
    
    func spyStoreSaves(count: Int = 1) -> [SessionsSynchronization.SessionStoreSessionData] {
        spyOnPublisher(store.$recordedHistory, count: count, filter: {
            guard $0.count > 0 else { return false }
            guard case .addSessions(_) = $0.last else { return false }
            return true
        }).last?.allWrittenData ?? []
    }
    
    func spyStoreRemove(count: Int = 1) -> [SessionUUID] {
        spyOnPublisher(store.$recordedHistory, count: count, filter: {
            guard $0.count > 0 else { return false }
            guard case .removeSessions(_) = $0.last else { return false }
            return true
        }).last?.allRemovedUUIDs ?? []
    }
    
    func spyOnPublisher<P: Publisher>(_ publisher: P, count: Int = 1, filter: @escaping ((P.Output) -> Bool) = { _ in true }) -> [P.Output] {
        let exp = expectation(description: "Waiting for the next \(count) publisher elements")
        var sub: AnyCancellable?
        var toReturn: [P.Output]!
        sub = publisher.filter(filter).collect(count).sink(receiveCompletion: { _ in
        }, receiveValue: { arrayOfElements in
            toReturn = arrayOfElements
            sub?.cancel()
            sub = nil
            exp.fulfill()
        })
        controller.triggerSynchronization()
        wait(for: [exp], timeout: 1.0)
        return toReturn
    }
    
    private func trueFilter<T>() -> (T) -> Bool { { _ in return true } }
    
    // MARK: Failure scenario simulations
    
    func simulateDownloadFailure(totalDownloads: Int, errorousDownloadIndex: Int) {
        setupWithPassthruDownloads(downloadUUIDs: .init(creating: .random, times: totalDownloads))
        let exp = expectation(description: "Will fail \(errorousDownloadIndex)th download")
        exp.assertForOverFulfill = false
        var sub: AnyCancellable?
        sub = downloadService.$recordedHistory.sink {
            guard $0.count > 0 else { return }
            let count = $0.count
            if count == errorousDownloadIndex {
                self.downloadService.toReturn = .failure(DummyError())
            } else {
                self.downloadService.toReturn = .success(.mock(uuid: $0.last!))
            }
            if count == totalDownloads { exp.fulfill() }
        }
        controller.triggerSynchronization()
        wait(for: [exp], timeout: 1.0)
        sub?.cancel()
        sub = nil
    }
    
    func simulateReadFailure(totalUploads: Int, errorousReadIndex: Int) {
        setupWithPassthruUploads(uploadUUIDs: .init(creating: .random, times: totalUploads))
        let exp = expectation(description: "Will fail \(errorousReadIndex)th read")
        exp.assertForOverFulfill = false
        var sub: AnyCancellable?
        sub = store.$recordedHistory.sink {
            let count = $0.allReads.count
            guard count > 0 else { return }
            if count == errorousReadIndex {
                self.store.readErrorToReturn = DummyError()
            } else {
                self.store.readErrorToReturn = nil
            }
            if count == totalUploads { exp.fulfill() }
        }
        controller.triggerSynchronization()
        wait(for: [exp], timeout: 1.0)
        sub?.cancel()
        sub = nil
    }
}
