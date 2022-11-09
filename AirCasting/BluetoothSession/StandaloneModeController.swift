// Created by Lunar on 09/11/2022.
//

import Foundation
import Resolver

protocol StandaloneModeController {
    func enterStandaloneMode(sessionUUID: SessionUUID)
}

struct DefaultStandaloneModeController: StandaloneModeController {
    @Injected private var sessionManager: MobilePeripheralSessionManager
    @Injected private var btManager: NewBluetoothManager
    
    func enterStandaloneMode(sessionUUID: SessionUUID) {
        // TODO: Refactor later
        sessionManager.enterStandaloneMode(sessionUUID: sessionUUID, centralManager: btManager.centralManager)
    }
}
