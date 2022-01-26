// Created by Lunar on 06/12/2021.
//

import Foundation
protocol SettingsViewModel: ObservableObject {
    func nextStep() -> ProceedToView
    func clearSDButtonTapped()
    func navigateToBackendButtonTapped() 
    
    var locationHandler: LocationHandler { get }
    var bluetoothHandler: BluetoothHandler { get }
    var sessionContext: CreateSessionContext { get }
    var urlProvider: BaseURLProvider { get }
    var logoutController: LogoutController { get }
    
    var SDClearingRouteProcess: Bool { get }
    var showBackendSettings: Bool { get set }
    var startSDClear: Bool { get set }
    var BTScreenGo: Bool { get set }
    var locationScreenGo: Bool { get set }
}

class SettingsViewModelDefault: SettingsViewModel, ObservableObject {
    
    @Published var showBackendSettings = false
    @Published var startSDClear = false
    @Published var BTScreenGo = false
    @Published var locationScreenGo = false
    
    var SDClearingRouteProcess = true
    
    var urlProvider: BaseURLProvider
    var logoutController: LogoutController
    let locationHandler: LocationHandler
    let bluetoothHandler: BluetoothHandler
    let sessionContext: CreateSessionContext


    init(locationHandler: LocationHandler, bluetoothHandler: BluetoothHandler, sessionContext: CreateSessionContext, urlProvider: BaseURLProvider, logoutController: LogoutController) {
        self.locationHandler = locationHandler
        self.bluetoothHandler = bluetoothHandler
        self.sessionContext = sessionContext
        self.urlProvider = urlProvider
        self.logoutController = logoutController
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



#if DEBUG
class DummySettingsViewModelDefault: SettingsViewModel {
    
    func navigateToBackendButtonTapped() {
        print("Button tapped")
    }
    
    func clearSDButtonTapped() {
        print("Button tapped")
    }
    
    func nextStep() -> ProceedToView {
        return .airBeam
    }
    
    var urlProvider: BaseURLProvider = DummyURLProvider()
    
    var logoutController: LogoutController = FakeLogoutController()
    
    var sessionContext: CreateSessionContext = CreateSessionContext()
    
    var locationHandler: LocationHandler = DummyDefaultLocationHandler()
    
    var bluetoothHandler: BluetoothHandler = DummyDefaultBluetoothHandler()
    
    var showBackendSettings: Bool = false
    
    var SDClearingRouteProcess: Bool = false
    
    var startSDClear: Bool = false
    
    var BTScreenGo: Bool = false
    
    var locationScreenGo: Bool = false
}
#endif
