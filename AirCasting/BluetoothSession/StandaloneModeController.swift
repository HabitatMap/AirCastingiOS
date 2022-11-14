// Created by Lunar on 09/11/2022.
//

import Foundation
import Resolver

protocol StandaloneModeController {
    func enterStandaloneMode(sessionUUID: SessionUUID)
}

struct DefaultStandaloneModeController: StandaloneModeController {
    @Injected private var sessionManager: MobilePeripheralSessionManager
    
    func enterStandaloneMode(sessionUUID: SessionUUID) {
        sessionManager.enterStandaloneMode(sessionUUID: sessionUUID)
    }
}
