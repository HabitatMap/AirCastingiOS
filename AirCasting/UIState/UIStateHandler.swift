// Created by Lunar on 10/02/2022.
//

import Foundation
import Resolver

protocol SessionCardUIStateHandler {
    func toggleCardExpanded(sessionUUID: SessionUUID, isSessionExternal: Bool)
    func changeSelectedStream(sessionUUID: SessionUUID, newStream: String, isSessionExternal: Bool)
}

class SessionCardUIStateHandlerDefault: SessionCardUIStateHandler {
    @Injected private var uiStorage: UIStorage
    
    func toggleCardExpanded(sessionUUID: SessionUUID, isSessionExternal: Bool = false) {
        uiStorage.accessStorage { storage in
            do {
                try storage.cardStateToggle(for: sessionUUID, isSessionExternal: isSessionExternal)
            } catch {
                Log.info("Error toggling card state \(error)")
            }
        }
    }
    
    func changeSelectedStream(sessionUUID: SessionUUID, newStream: String, isSessionExternal: Bool = false) {
        uiStorage.accessStorage { storage in
            do {
                try storage.changeStream(for: sessionUUID, stream: newStream, isSessionExternal: isSessionExternal)
            } catch {
                Log.info("Error changing stream \(error)")
            }
        }
    }
    
}
