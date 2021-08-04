// Created by Lunar on 02/08/2021.
//

import Foundation

enum ProceedToView {
    case AB
    case location
    case bluetooth
    case mobile
}

class ChooseSessionTypeViewModel {
    
    var locationHandler: LocationHandler
    var bluetoothHandler: BluetoothHandler
    
    var userSettings: UserSettings
    var sessionContext: CreateSessionContext
    let urlProvider: BaseURLProvider

    init(locationHandler: LocationHandler, bluetoothHandler: BluetoothHandler, userSettings: UserSettings, sessionContext: CreateSessionContext, urlProvider: BaseURLProvider) {
        self.locationHandler = locationHandler
        self.bluetoothHandler = bluetoothHandler
        self.userSettings = userSettings
        self.sessionContext = sessionContext
        self.urlProvider = urlProvider
    }

    func fixSessionNextStep() -> ProceedToView {
        if locationHandler.isLocationDenied() {
            return .location
        } else {
            if bluetoothHandler.isBluetoothDenied() {
                return .bluetooth
            } else {
                return .AB
            }
        }
    }
    
    func mobileSessionNextStep() -> ProceedToView {
        if locationHandler.isLocationDenied() {
            return .location
        } else {
            return .mobile
        }
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
