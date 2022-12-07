// Created by Lunar on 15/12/2021.
//

import Foundation
import SwiftUI
import CoreData
import Resolver

protocol EditViewModel: ObservableObject {
    var sessionName: String { get set }
    var sessionTags: String { get set }
    var isSessionDownloaded: Bool { get set }
    var alert: AlertInfo? { get set }
    var shouldShowError: Bool { get }
    var shouldDismiss: Bool { get }

    func saveChanges()
    func viewAppeared()
}

class EditSessionViewModel: EditViewModel {
    @Published var isSessionDownloaded = false
    @Published var sessionName = ""
    @Published var sessionTags = ""
    @Published var shouldShowError = false
    @Published var shouldDismiss = false
    @Published var alert: AlertInfo?
    @Injected private var sessionStorage: SessionEditingStorage
    @Injected private var sessionDownloader: SingleSessionDownloader
    @Injected private var sessionUpdateService: SessionUpdateService
    @Injected private var networkChecker: NetworkChecker
    private let sessionUUID: SessionUUID
    private var sessionAlreadySynced: Bool

    init(sessionUUID: SessionUUID, sessionName: String, sessionTags: String, sessionSynced: Bool) {
        self.sessionUUID = sessionUUID
        self.sessionName = sessionName
        self.sessionTags = sessionTags
        sessionAlreadySynced = sessionSynced
    }

    func saveChanges() {
        guard !sessionName.isEmpty else {
            shouldShowError = true
            return
        }
        
        guard networkChecker.connectionAvailable else {
            alert = InAppAlerts.noNetworkEditAlert(dismiss: nil)
            return
        }
        
        let name = sessionName
        let tags = sessionTags
        sessionStorage.accessStorage { [self] storage in
            do {
                try storage.updateSessionNameAndTags(name: name,
                                                     tags: tags,
                                                     for: sessionUUID)
                guard sessionAlreadySynced else {
                    DispatchQueue.main.async {
                        self.shouldDismiss = true
                    }
                    return
                }
                
                let session = try storage.getExistingSession(with: sessionUUID)
                sessionUpdateService.updateSession(session: session) { result in
                    switch result {
                    case .success(let session):
                        self.sessionStorage.accessStorage { storage in
                            do {
                                try storage.updateVersion(for: self.sessionUUID, to: session.version)
                                Log.info("Updated session version to: \(session.version)")
                            } catch {
                                Log.error("Error while saving edited session name and tags \(error).")
                                self.showAlert(InAppAlerts.failedSavingData(dismiss: { self.dismissView() }))
                            }
                        }
                    case .failure(let error):
                        Log.error("Error while sending updated session to backend \(error).")
                        self.showAlert(InAppAlerts.failedSavingData(dismiss: { self.dismissView() }))
                    }
                    DispatchQueue.main.async {
                        self.shouldDismiss = true
                    }
                }
            } catch {
                Log.info("Error while saving edited session name and tags.")
                self.showAlert(InAppAlerts.failedSavingData { self.dismissView() })
            }
        }
    }

    func viewAppeared() {
        guard sessionAlreadySynced else {
            isSessionDownloaded = true
            return
        }
        
        guard networkChecker.connectionAvailable else {
            alert = InAppAlerts.noNetworkEditAlert(dismiss: { self.dismissView() })
            return
        }
        
        sessionDownloader.downloadSessionNameAndTags(with: sessionUUID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let sessionData):
                self.updateSessionNameAndTagsWithBackendData(name: sessionData.title, tags: sessionData.tagList) {
                    DispatchQueue.main.async {
                        self.sessionName = sessionData.title
                        self.sessionTags = sessionData.tagList
                        self.isSessionDownloaded = true
                    }
                }
            case .failure(let error):
                Log.error("Error downloading session data for edit view: \(error.localizedDescription)")
                self.showAlert(InAppAlerts.failedToDownload(dismiss: { self.dismissView() }))
            }
        }
    }

    private func updateSessionNameAndTagsWithBackendData(name: String, tags: String, closure: @escaping () -> ()) {
        self.sessionStorage.accessStorage { [self] storage in
            do {
                try storage.updateSessionNameAndTags(name: name,
                                                     tags: tags,
                                                     for: self.sessionUUID)
                closure()
            } catch {
                Log.error("Failed to save new session name and tags")
                self.showAlert(InAppAlerts.failedSavingData { self.dismissView() })
            }
        }
    }

    private func showAlert(_ alert: AlertInfo) {
        DispatchQueue.main.async {
            self.alert = alert
        }
    }

    private func dismissView() {
        DispatchQueue.main.async {
            self.shouldDismiss = true
        }
    }
}
