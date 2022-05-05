// Created by Lunar on 25/04/2022.
//

import Foundation
import Resolver

class EditLocationlessSessionViewModel: EditViewModel {
    @Published var isSessionDownloaded = false
    @Published var sessionName: String
    @Published var sessionTags: String
    @Published var shouldShowError = false
    @Published var shouldDismiss = false
    @Published var alert: AlertInfo?
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    private let sessionUUID: SessionUUID
    
    init(sessionUUID: SessionUUID, sessionName: String, sessionTags: String) {
        self.sessionUUID = sessionUUID
        self.sessionName = sessionName
        self.sessionTags = sessionTags
    }
    
    func saveChanges() {
        guard !sessionName.isEmpty else {
            shouldShowError = true
            return
        }
        let name = sessionName
        let tags = sessionTags
        measurementStreamStorage.accessStorage { [weak self] storage in
            guard let self = self else { return }
            do {
                try storage.updateSessionNameAndTags(name: name,
                                                     tags: tags,
                                                     for: self.sessionUUID)
                self.dismissView()
            } catch {
                Log.info("Error while saving edited session name and tags.")
                self.showAlert(InAppAlerts.failedSavingData { self.dismissView() })
            }
        }
    }
    
    func viewAppeared() {
        isSessionDownloaded = true
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
