// Created by Lunar on 02/08/2021.
//

import Foundation
import CoreBluetooth
import Resolver

enum ProceedToView {
    case airBeam
    case location
    case bluetooth
    case mobile
}

// [RESOLVER] Move this VM init to view
class ChooseSessionTypeViewModel {
    
    @Injected private var locationHandler: LocationHandler
    @Injected private var bluetoothHandler: BluetoothHandler
    @Injected private var userSettings: UserSettings
    private let sessionContext: CreateSessionContext
    @Injected private var urlProvider: URLProvider
    
    var passSessionContext: CreateSessionContext {
        return sessionContext
    }

    init(sessionContext: CreateSessionContext) {
        self.sessionContext = sessionContext
    }

    func fixedSessionNextStep() -> ProceedToView {
        guard !bluetoothHandler.isBluetoothDenied() else { return .bluetooth }
        return .airBeam
    }
    
    func mobileSessionNextStep() -> ProceedToView {
        !userSettings.disableMapping && locationHandler.isLocationDenied() ? .location : .mobile
    }
    
    func createNewSession(isSessionFixed: Bool) {
        sessionContext.sessionUUID = SessionUUID()
        if isSessionFixed {
            sessionContext.contribute = true
            sessionContext.sessionType = SessionType.fixed
        } else {
            sessionContext.contribute = userSettings.contributingToCrowdMap
            sessionContext.locationless = userSettings.disableMapping
            sessionContext.sessionType = SessionType.mobile
        }
    }
}
