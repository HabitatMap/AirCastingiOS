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
    func downloadSessionAndReloadView()
}

class EditSessionViewModel: EditViewModel {
    @Published var isSessionDownloaded = false
    @Published var sessionName = ""
    @Published var sessionTags = ""
    @Published var shouldShowError = false
    @Published var shouldDismiss = false
    @Published var alert: AlertInfo?
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    @Injected private var sessionDownloader: SingleSessionDownloader
    @Injected private var sessionUpdateService: SessionUpdateService
    private let sessionUUID: SessionUUID
    
    init(sessionUUID: SessionUUID) {
        self.sessionUUID = sessionUUID
    }
    
    func saveChanges() {
        guard !sessionName.isEmpty else {
            shouldShowError = true
            return
        }
        let name = sessionName
        let tags = sessionTags
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.updateSessionNameAndTags(name: name,
                                                     tags: tags,
                                                     for: sessionUUID)
                let session = try storage.getExistingSession(with: sessionUUID)
                sessionUpdateService.updateSession(session: session) { result in
                    switch result {
                    case .success(let session):
                        do {
                            try storage.updateVersion(for: sessionUUID,to: session.version)
                        } catch {
                            Log.info("Error while saving edited session name and tags \(error).")
                            showAlert(InAppAlerts.failedSavingData(dismiss: self.dismissView()))
                        }
                    case .failure(let error):
                        Log.info("Error while sending updated session to backend \(error).")
                        showAlert(InAppAlerts.failedSavingData(dismiss: self.dismissView()))
                    }
                    DispatchQueue.main.async {
                        shouldDismiss = true
                    }
                }
            } catch {
                Log.info("Error while saving edited session name and tags.")
            }
        }
    }
    
    func downloadSessionAndReloadView() {
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
                self.showAlert(InAppAlerts.failedToDownload(dismiss: self.dismissView()))
            }
        }
    }
    
    private func updateSessionNameAndTagsWithBackendData(name: String, tags: String, closure: @escaping () -> ()) {
        self.measurementStreamStorage.accessStorage { [self] storage in
            do {
                try storage.updateSessionNameAndTags(name: name,
                                                     tags: tags,
                                                     for: self.sessionUUID)
                closure()
            } catch {
                Log.error("Failed to save new session name and tags")
                showAlert(InAppAlerts.failedSavingData(dismiss: self.dismissView()))
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
