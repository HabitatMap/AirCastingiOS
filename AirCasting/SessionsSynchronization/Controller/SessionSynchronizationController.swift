// Created by Lunar on 10/06/2021.
//

import Foundation
import Combine
import CoreLocation

final class SessionSynchronizationController: SessionSynchronizer {
    
    /// A plugin point for error handlers
    var errorStream: SessionSynchronizerErrorStream?
    
    private let synchronizationContextProvider: SessionSynchronizationContextProvidable
    private let downstream: SessionDownstream
    private let upstream: SessionUpstream
    private let store: SessionSynchronizationStore
    private let dataConverter = SynchronizationDataConverter()
    private(set) lazy var syncInProgress: CurrentValueSubject<Bool, Never> = .init(false)
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
    func triggerSynchronization(options: SessionSynchronizationOptions, completion: (() -> Void)?) {
        lock.lock(); defer { lock.unlock() }
        if syncInProgress.value { return }
        syncInProgress.value = true
        
        let onFinish = {
            Log.info("[SYNC] Ending synchronization")
            completion?()
            self.syncInProgress.value = false
        }
        
        startSynchronization(options: options)
            .handleEvents(receiveCancel: onFinish)
            .sink(receiveCompletion: { [weak self] result in
                defer { onFinish() }
                guard let self = self else { return }
                if case .failure(let error) = result {
                    let syncError = self.translateError(streamError: error)
                    self.errorStream?.handleSyncError(syncError)
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    func stopSynchronization() {
        lock.lock(); defer { lock.unlock() }
        Log.info("[SYNC] Forced stopping synchronization")
        cancellables = []
    }
    
    // MARK: - SingleSessionSynchronizer
    func downloadSingleSession(sessionUUID: SessionUUID, completion: @escaping () -> Void) {
        processDownloads(context: .init(needToBeDownloaded: [sessionUUID], needToBeUploaded: [], removed: []))
            .sink { _ in
                completion()
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    // MARK: - Private
    
    private func translateError(streamError: Error) -> SessionSynchronizerError {
        if let urlError = streamError as? URLError, urlError.code == URLError.Code.notConnectedToInternet {
            return .noConnection
        }
        if let syncError = streamError as? SessionSynchronizerError {
            return syncError
        }
        return .unknown
    }
    
    private func startSynchronization(options: SessionSynchronizationOptions) -> AnyPublisher<Void, Error> {
        Log.info("[SYNC] Starting synchronization")
        // Let's make ourselves a favor and place that warning here 🔥
        if Thread.isMainThread { Log.warning("[SYNC] Synchronization started on main thread, reconsider") }
        return store
            .getLocalSessionList()
            .mapError({ _ in SessionSynchronizerError.cannotFetchLocalData })
            .logError(message: "[SYNC] Couldn't fetch local sessions")
            .flatMap {
                self.getSynchronizationContext(localSessions: $0)
                    .onError({ _ in self.errorStream?.handleSyncError(.cannotFetchSyncContext) })
                    .filterError(self.isConnectionError(_:))
                    .logError(message: "[SYNC] Couldn't retrieve sync context")
            }
            .flatMap { context in
                Publishers.MergeMany (
                    // Should this be extracted to separate strategy objects?
                    //
                    //                                           I think: no.
                    options.contains(.download) ? self.processDownloads(context: context) : Empty<Void, Error>().eraseToAnyPublisher(),
                    options.contains(.upload) ? self.processUploads(context: context) : Empty<Void, Error>().eraseToAnyPublisher(),
                    options.contains(.remove) ? self.processRemoves(context: context) : Empty<Void, Error>().eraseToAnyPublisher()
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
            .flatMap(self.downloadSingleSession(uuid:))
            .collect()
            .flatMap(self.saveSessions(downloadedSessions:))
            .eraseToAnyPublisher()
    }
    
    private func downloadSingleSession(uuid: SessionUUID) -> AnyPublisher<SessionsSynchronization.SessionDownstreamData, Error> {
        downstream
            .download(session: uuid)
            .onError({ _ in self.errorStream?.handleSyncError(.downloadFailed(uuid)) })
            .filterError(self.isConnectionError(_:))
            .logError(message: "[SYNC] Error downloading session")
            .eraseToAnyPublisher()
    }
    
    private func saveSessions(downloadedSessions: [SessionsSynchronization.SessionDownstreamData]) -> AnyPublisher<Void, Never> {
        let dataStoreEntries = downloadedSessions.map(dataConverter.convertDownloadToSession(_:))
        Log.verbose("[SYNC] Adding \(downloadedSessions.count) sessions to store")
        return store
            .addSessions(with: dataStoreEntries)
            .onError({ _ in self.errorStream?.handleSyncError(.storeWriteFailure(dataStoreEntries.map(\.uuid))) })
            .logErrorAndComplete(message: "[SYNC] Error adding session to store")
            .eraseToAnyPublisher()
    }
    
    private func processUploads(context: SessionsSynchronization.SynchronizationContext) -> AnyPublisher<Void, Error> {
        Just(context.needToBeUploaded)
            .logVerbose { "[SYNC] Uploading \($0.count) sessions" }
            .flatMap { $0.publisher }
            .flatMap { uuid in
                self.store
                    .readSession(with: uuid)
                    .onError({ _ in self.errorStream?.handleSyncError(.storeReadFailure(uuid)) })
                    .logErrorAndComplete(message: "[SYNC] Error reading session")
            }
            .map(
                dataConverter.convertSessionToUploadData(_:)
            )
            .flatMap { uploadData in
                self.upstream
                    .upload(session: uploadData)
                    .onError({ _ in self.errorStream?.handleSyncError(.uploadFailure(uploadData.uuid)) })
                    .filterError(self.isConnectionError(_:))
                    .logError(message: "[SYNC] Uploading session failed")
            }
            .eraseToAnyPublisher()
    }
    
    private func processRemoves(context: SessionsSynchronization.SynchronizationContext) -> AnyPublisher<Void, Error> {
        Just(context.removed)
            .logVerbose { "[SYNC] Removing \($0.count) sessions" }
            .flatMap { uuids in
                self.store.removeSessions(with: uuids)
                    .onError({ _ in self.errorStream?.handleSyncError(.storeDeleteFailure(uuids)) })
            }
            .logError(message: "[SYNC] Couldn't remove sessions")
            .eraseToAnyPublisher()
    }
    
    private func isConnectionError(_ error: Error) -> Bool {
        (error as? URLError)?.code == .notConnectedToInternet
    }
}
