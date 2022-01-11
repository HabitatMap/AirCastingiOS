// Created by Lunar on 06/12/2021.
//

import Foundation
import Resolver
#warning("Move whole logic of settingsView to this ViewModel")
protocol SettingsViewModel {
    func nextStep() -> ProceedToView
    var locationHandler: LocationHandler { get }
    var sessionContext: CreateSessionContext { get }
}

class SettingsViewModelDefault: SettingsViewModel {
    
    let locationHandler: LocationHandler
    @Injected private var bluetoothHandler: BluetoothHandler
    let sessionContext: CreateSessionContext


    init(locationHandler: LocationHandler, sessionContext: CreateSessionContext) {
        self.locationHandler = locationHandler
        self.sessionContext = sessionContext
    }

    func nextStep() -> ProceedToView {
        guard !locationHandler.isLocationDenied() else { return .location }
        guard !bluetoothHandler.isBluetoothDenied() else { return .bluetooth }
        return .airBeam
    }
}
