// Created by Lunar on 15/12/2021.
//

import Foundation
import SwiftUI
import CoreData

class EditSessionViewModel: ObservableObject {
    
    @Published var sessionName = ""
    @Published var sessionTags = ""
    private let measurementStreamStorage: MeasurementStreamStorage
    private let sessionUpdateService: SessionUpdateService

    init(measurementStreamStorage: MeasurementStreamStorage, sessionUpdateService: SessionUpdateService) {
        self.measurementStreamStorage = measurementStreamStorage
        self.sessionUpdateService = sessionUpdateService
    }
    
    func saveChanges(for uuid: SessionUUID, completion: @escaping () -> Void) {
        guard !sessionName.isEmpty else { return }
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
    
    func reloadWith(_ sessionUUID: SessionUUID) {
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

protocol EditViewModel {
    var sessionName: String { get set }
    var sessionTags: String { get set }
}
