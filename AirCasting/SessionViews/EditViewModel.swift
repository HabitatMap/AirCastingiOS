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
    var shouldShowError: Bool { get }
    var didSave: Bool { get }
    
    func saveChanges()
    func downloadSessionAndReloadView()
    func reload()
}

class EditSessionViewModel: EditViewModel {
    
    @Published var isSessionDownloaded = false
    @Published var sessionName = ""
    @Published var sessionTags = ""
    @Published var shouldShowError = false
    @Published var didSave = false
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    @Injected private var sessionSynchronizer: SingleSessionSynchronizer
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
                sessionUpdateService.updateSession(session: session) {
                    DispatchQueue.main.async {
                        didSave = true
                    }
                }
            } catch {
                Log.info("Error while saving edited session name and tags.")
            }
        }
    }
    
    func downloadSessionAndReloadView() {
        sessionSynchronizer.downloadSingleSession(sessionUUID: sessionUUID) {
            DispatchQueue.main.async {  
                self.isSessionDownloaded = true
                self.reload()
            }
        }
    }
    
    internal func reload() {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                let session = try storage.getExistingSession(with: sessionUUID)
                guard let name = session.name else { return }
                let tags = session.tags ?? ""
                DispatchQueue.main.async {
                    sessionName = name
                    sessionTags = tags
                }
            } catch {
                Log.error("Error reloading session data for edit view.")
            }
        }
    }
}
