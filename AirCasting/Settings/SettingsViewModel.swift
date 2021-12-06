// Created by Lunar on 06/12/2021.
//

import Foundation

protocol SettingsViewModel {
    func NextStep() -> ProceedToView
}

class SettingsViewModelDefault: SettingsViewModel, ObservableObject {
    
    let locationHandler: LocationHandler
    private let bluetoothHandler: BluetoothHandler


    init(locationHandler: LocationHandler, bluetoothHandler: BluetoothHandler) {
        self.locationHandler = locationHandler
        self.bluetoothHandler = bluetoothHandler
    }

    func NextStep() -> ProceedToView {
        guard !locationHandler.isLocationDenied() else { return .location }
        guard !bluetoothHandler.isBluetoothDenied() else { return .bluetooth }
        return .airBeam
    }
}

class DummySettingsViewModelDefault: SettingsViewModel {
    func NextStep() -> ProceedToView {
        return .airBeam
    }
    
    
}
