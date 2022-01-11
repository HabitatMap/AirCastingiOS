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

class ChooseSessionTypeViewModel {
    
    let locationHandler: LocationHandler
    @Injected private var bluetoothHandler: BluetoothHandler
    private let userSettings: UserSettings
    private let sessionContext: CreateSessionContext
    private let urlProvider: BaseURLProvider
    private var bluetoothManagerState: CBManagerState
    
    var passURLProvider: BaseURLProvider {
        return urlProvider
    }
    
    var passLocationHandler: LocationHandler {
        return locationHandler
    }
    
    var passSessionContext: CreateSessionContext {
        return sessionContext
    }
    
    var passUserSettings: UserSettings {
        return userSettings
    }

    init(locationHandler: LocationHandler, userSettings: UserSettings, sessionContext: CreateSessionContext, urlProvider: BaseURLProvider, bluetoothManagerState: CBManagerState) {
        self.locationHandler = locationHandler
        self.userSettings = userSettings
        self.sessionContext = sessionContext
        self.urlProvider = urlProvider
        self.bluetoothManagerState = bluetoothManagerState
    }

    func fixedSessionNextStep() -> ProceedToView {
        guard !locationHandler.isLocationDenied() else { return .location }
        guard !bluetoothHandler.isBluetoothDenied() else { return .bluetooth }
        return .airBeam
    }
    
    func mobileSessionNextStep() -> ProceedToView {
        locationHandler.isLocationDenied() ? .location : .mobile
    }
    
    func createNewSession(isSessionFixed: Bool) {
        sessionContext.sessionUUID = SessionUUID()
        if isSessionFixed {
            sessionContext.contribute = true
            sessionContext.sessionType = SessionType.fixed
        } else {
            sessionContext.contribute = userSettings.contributingToCrowdMap
            sessionContext.sessionType = SessionType.mobile
        }
    }
}
