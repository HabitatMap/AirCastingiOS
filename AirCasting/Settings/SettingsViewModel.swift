// Created by Lunar on 06/12/2021.
//

import Foundation
#warning("Move whole logic of settingsView to this ViewModel")
protocol SettingsViewModel {
    func nextStep() -> ProceedToView
    var locationHandler: LocationHandler { get }
    var bluetoothHandler: BluetoothHandler { get }
    var sessionContext: CreateSessionContext { get }
}

class SettingsViewModelDefault: SettingsViewModel {
    
    let locationHandler: LocationHandler
    let bluetoothHandler: BluetoothHandler
    let sessionContext: CreateSessionContext


    init(locationHandler: LocationHandler, bluetoothHandler: BluetoothHandler, sessionContext: CreateSessionContext) {
        self.locationHandler = locationHandler
        self.bluetoothHandler = bluetoothHandler
        self.sessionContext = sessionContext
    }

    func nextStep() -> ProceedToView {
        guard !locationHandler.isLocationDenied() else { return .location }
        guard !bluetoothHandler.isBluetoothDenied() else { return .bluetooth }
        return .airBeam
    }
}

#if DEBUG
class DummySettingsViewModelDefault: SettingsViewModel {
    var sessionContext: CreateSessionContext = CreateSessionContext()
    
    var locationHandler: LocationHandler = DummyDefaultLocationHandler()
    
    var bluetoothHandler: BluetoothHandler = DummyDefaultBluetoothHandler()
    
    func nextStep() -> ProceedToView {
        return .airBeam
    }
    
}
#endif
