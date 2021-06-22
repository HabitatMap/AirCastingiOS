// Created by Lunar on 10/06/2021.
//

import Foundation
import Combine
import CoreLocation


class SessionSynchronizationController: SessionSynchronizer {
    private let gate = PassthroughSubject<Void, Never>()
    
    private let synchronizationContextProvider: SessionSynchronizationContextProvidable
    private let downstream: SessionDownstream
    private let upstream: SessionUpstream
    private let store: SessionSynchronizationStore
    
    // Progress tracking for filtering requests while already syncing
    // (can this be somehow moved to a custom operator or something?)
    private var syncInProgress: Bool = false
    // Simple lock is sufficient here, no need for GCD
    private let lock = NSRecursiveLock()
    
    private var cancellables: [AnyCancellable] = []
    
    init(synchronizationContextProvider: SessionSynchronizationContextProvidable,
         downstream: SessionDownstream,
         upstream: SessionUpstream,
         store: SessionSynchronizationStore) {
        self.synchronizationContextProvider = synchronizationContextProvider
        self.downstream = downstream
        self.upstream = upstream
        self.store = store
    }
    
    func triggerSynchronization(completion: (() -> Void)?) {
        lock.lock(); defer { lock.unlock() }
        if syncInProgress { return }
        syncInProgress = true
        
        startSynchronization()
            .sink(receiveCompletion: { _ in
                Log.info("[SYNC] Ending synchronization")
                completion?()
                self.syncInProgress = false
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func stopSynchronization() {
        lock.lock(); defer { lock.unlock() }
        Log.info("[SYNC] Forced stopping synchronization")
        syncInProgress = false
        cancellables = []
    }
    
    private func startSynchronization() -> AnyPublisher<Void, Error> {
        Log.info("[SYNC] Starting synchronization")
        // Let's make ourselves a favor and place that warning here 🔥
        if Thread.isMainThread { Log.warning("[SYNC] Synchronization started on main thread, reconsider") }
        return store
            .getLocalSessionList()
            .logError(message: "[SYNC] Couldn't fetch local sessions")
            .flatMap {
                self.getSynchronizationContext(localSessions: $0)
            }
            .logError(message: "[SYNC] Couldn't retrieve sync context")
            .flatMap { context in
                Publishers.MergeMany (
                    // Should this be extracted to separate strategy objects?
                    //
                    //                                           I think: no.
                    self.processDownloads(context: context),
                    self.processUploads(context: context),
                    self.processRemoves(context: context)
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func getSynchronizationContext(localSessions: [SessionsSynchronization.Metadata]) -> AnyPublisher<SessionsSynchronization.SynchronizationContext, Error> {
        self.synchronizationContextProvider
            .getSynchronizationContext(localSessions: localSessions)
            .handleEvents(receiveOutput: {
                Log.verbose("[SYNC] Context retrieved: \($0)")
            })
            .eraseToAnyPublisher()
    }
    
    private func processDownloads(context: SessionsSynchronization.SynchronizationContext) -> AnyPublisher<Void, Error> {
        context.needToBeDownloaded
            .publisher
            .flatMap { self.downloadSingleSession(uuid: $0) }
            .collect()
            .flatMap { self.saveSessions(downloadedSessions: $0) }
            .eraseToAnyPublisher()
    }
    
    private func downloadSingleSession(uuid: SessionUUID) -> AnyPublisher<SessionsSynchronization.SessionDownstreamData, Never> {
        downstream
            .download(session: uuid)
            .logErrorAndComplete(message: "[SYNC] Error downloading session")
            .eraseToAnyPublisher()
    }
    
    private func saveSessions(downloadedSessions: [SessionsSynchronization.SessionDownstreamData]) -> AnyPublisher<Void, Error> {
        let dataStoreEntries = downloadedSessions.map(SynchronizationDataConterter.convertDownloadToSession(_:))
        Log.verbose("[SYNC] Adding \(downloadedSessions.count) sessions to store")
        return store
            .addSessions(with: dataStoreEntries)
            .logError(message: "[SYNC] Error adding session to store")
            .eraseToAnyPublisher()
    }
    
    private func processUploads(context: SessionsSynchronization.SynchronizationContext) -> AnyPublisher<Void, Error> {
        Just(context.needToBeUploaded)
            .logVerbose { "[SYNC] Uploading \($0.count) sessions" }
            .flatMap { $0.publisher }
            .flatMap { uuid in
                self.store
                    .readSession(with: uuid)
                    .logErrorAndComplete(message: "[SYNC] Error reading session")
            }
            .map(
                SynchronizationDataConterter.convertSessionToUploadData(_:)
            )
            .flatMap { uploadData in
                self.upstream
                    .upload(session: uploadData)
                    .logError(message: "[SYNC] Uploading session failed")
            }
            .eraseToAnyPublisher()
    }
    
    private func processRemoves(context: SessionsSynchronization.SynchronizationContext) -> AnyPublisher<Void, Error> {
        Just(context.removed)
            .logVerbose { "[SYNC] Removing \($0.count) sessions" }
            .flatMap { self.store.removeSessions(with: $0) }
            .logError(message: "[SYNC] Couldn't remove sessions")
            .eraseToAnyPublisher()
    }
}
