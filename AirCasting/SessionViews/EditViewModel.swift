// Created by Lunar on 15/12/2021.
//

import Foundation
import SwiftUI
import CoreData

protocol EditViewModel: ObservableObject {
    var sessionName: String { get set }
    var sessionTags: String { get set }
    var isSessionDownloaded: Bool { get set }
    
    func saveChanges(for uuid: SessionUUID, completion: @escaping () -> Void)
    func downloadSessionAndReloadView(sessionUUID: SessionUUID)
    func reloadWith(_ sessionUUID: SessionUUID)
}

class EditSessionViewModel: EditViewModel {
    
    @Published var isSessionDownloaded = false
    @Published var sessionName = ""
    @Published var sessionTags = ""
    @Published var shouldShowError = false
    private let measurementStreamStorage: MeasurementStreamStorage
    let sessionSynchronizer: SessionSynchronizer
    let sessionUpdateService: SessionUpdateService

    init(measurementStreamStorage: MeasurementStreamStorage,  sessionSynchronizer: SessionSynchronizer, sessionUpdateService: SessionUpdateService) {
        self.measurementStreamStorage = measurementStreamStorage
        self.sessionSynchronizer = sessionSynchronizer
        self.sessionUpdateService = sessionUpdateService
    }
    
    func saveChanges(for uuid: SessionUUID, completion: @escaping () -> Void) {
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
                                                     for: uuid)
                let session = try storage.getExistingSession(with: uuid)
                sessionUpdateService.updateSession(session: session, completion: completion)
            } catch {
                Log.info("Error while saving edited session name and tags.")
            }
        }
    }
    
    func downloadSessionAndReloadView(sessionUUID: SessionUUID) {
        sessionSynchronizer.downloadSingleSession(sessionUUID: sessionUUID) {
            DispatchQueue.main.async {  
                self.isSessionDownloaded = true
                self.reloadWith(sessionUUID)
            }
        }
    }
    
    internal func reloadWith(_ sessionUUID: SessionUUID) {
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
