// Created by Lunar on 10/02/2022.
//

import Foundation
import Resolver

protocol UIStateHandler {
    func cardToggle(sessionUUID: SessionUUID)
    func streamChange(sessionUUID: SessionUUID, newStream: String)
}

class UIStateHandlerDefault: UIStateHandler {
    @Injected private var UIStorage: UIStorage
    
    func cardToggle(sessionUUID: SessionUUID) {
        UIStorage.accessStorage { storage in
            do {
                try storage.cardStateToggle(for: sessionUUID)
            } catch {
                Log.info("(UIState) Error toggling card state \(error)")
            }
        }
    }
    
    func streamChange(sessionUUID: SessionUUID, newStream: String) {
        UIStorage.accessStorage { storage in
            do {
                try storage.changeStream(for: sessionUUID, stream: newStream)
            } catch {
                Log.info("(UIState) Error changing stream \(error)")
            }
        }
    }
    
}
