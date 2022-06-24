// Created by Lunar on 06/12/2021.
//

import Foundation
import Resolver

class SettingsViewModel: ObservableObject {
    
    @Published var showBackendSettings = false
    @Published var startSDClear = false
    @Published var BTScreenGo = false
    @Published var locationScreenGo = false
    
    var SDClearingRouteProcess = true
    let username = "\(KeychainStorage(service: Bundle.main.bundleIdentifier!).getProfileData(.username))"
    
    @Injected private var urlProvider: URLProvider
    @Injected private var locationHandler: LocationHandler
    @Injected private var bluetoothHandler: BluetoothHandler
    let sessionContext: CreateSessionContext


    init(sessionContext: CreateSessionContext) {
        self.sessionContext = sessionContext
    }
    
    func navigateToBackendButtonTapped() {
        showBackendSettings.toggle()
    }

    func nextStep() -> ProceedToView {
        guard !locationHandler.isLocationDenied() else { return .location }
        guard !bluetoothHandler.isBluetoothDenied() else { return .bluetooth }
        return .airBeam
    }
    
    func clearSDButtonTapped() {
        switch nextStep() {
        case .bluetooth: BTScreenGo.toggle()
        case .location: locationScreenGo.toggle()
        case .airBeam, .mobile: startSDClear.toggle()
        }
    }
}
