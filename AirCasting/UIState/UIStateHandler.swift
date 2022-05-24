// Created by Lunar on 10/02/2022.
//

import Foundation
import Resolver

protocol SessionCardUIStateHandler {
    func toggleCardExpanded(sessionUUID: SessionUUID)
    func changeSelectedStream(sessionUUID: SessionUUID, newStream: String)
}

class SessionCardUIStateHandlerDefault: SessionCardUIStateHandler {
    @Injected private var uiStorage: UIStorage
    
    func toggleCardExpanded(sessionUUID: SessionUUID) {
        uiStorage.accessStorage { storage in
            do {
                try storage.cardStateToggle(for: sessionUUID)
            } catch {
                Log.info("Error toggling card state \(error)")
            }
        }
    }
    
    func changeSelectedStream(sessionUUID: SessionUUID, newStream: String) {
        uiStorage.accessStorage { storage in
            do {
                try storage.changeStream(for: sessionUUID, stream: newStream)
            } catch {
                Log.info("Error changing stream \(error)")
            }
        }
    }
    
}
