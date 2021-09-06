// Created by Lunar on 02/08/2021.
//

import Foundation
import CoreBluetooth

enum ProceedToView {
    case airBeam
    case location
    case bluetooth
    case mobile
}

class ChooseSessionTypeViewModel {
    
    let locationHandler: LocationHandler
    private let bluetoothHandler: BluetoothHandler
    private let userSettings: UserSettings
    private let sessionContext: CreateSessionContext
    private let urlProvider: BaseURLProvider
    private var bluetoothManager: BluetoothManager
    private var bluetoothManagerState: CBManagerState
    
    var passURLProvider: BaseURLProvider {
        return urlProvider
    }
    
    var passLocationHandler: LocationHandler {
        return locationHandler
    }
    
    var passBluetoothHandler: BluetoothHandler {
        return bluetoothHandler
    }
    
    var passSessionContext: CreateSessionContext {
        return sessionContext
    }
    
    var passUserSettings: UserSettings {
        return userSettings
    }
    
    var passBluetoothManager: BluetoothManager {
        return bluetoothManager
    }

    init(locationHandler: LocationHandler, bluetoothHandler: BluetoothHandler, userSettings: UserSettings, sessionContext: CreateSessionContext, urlProvider: BaseURLProvider, bluetoothManager: BluetoothManager, bluetoothManagerState: CBManagerState) {
        self.locationHandler = locationHandler
        self.bluetoothHandler = bluetoothHandler
        self.userSettings = userSettings
        self.sessionContext = sessionContext
        self.urlProvider = urlProvider
        self.bluetoothManager = bluetoothManager
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
