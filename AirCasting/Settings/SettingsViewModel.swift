// Created by Lunar on 06/12/2021.
//

import Foundation
import Resolver

class SettingsViewModel: ObservableObject {
    @Published var showBackendSettings = false
    @Published var showMicrophoneManualCalibation = false
    @Published var startSDClear = false
    @Published var BTScreenGo = false
    @Published var locationScreenGo = false
    @Published var alert: AlertInfo?
    @Published var dormantAlert = false
    
    var SDClearingRouteProcess = true
    let username = "\(KeychainStorage(service: Bundle.main.bundleIdentifier!).getProfileData(for: .username))"
    
    @Injected private var locationAuthorization: LocationAuthorization
    @Injected private var bluetoothHandler: BluetoothPermisionsChecker
    @Injected private var controller: SettingsController
    @Injected private var userSettings: UserSettings
    @Injected private var networkChecker: NetworkChecker
    let sessionContext: CreateSessionContext


    init(sessionContext: CreateSessionContext) {
        self.sessionContext = sessionContext
        dormantAlert = userSettings.dormantSessionsAlert
    }
    
    func navigateToBackendButtonTapped() {
        showBackendSettings.toggle()
    }
    
    func manualMicrophoneCalibrationTapped() {
        showMicrophoneManualCalibation = true
    }

    func nextStep() -> ProceedToView {
        guard locationAuthorization.locationState != .denied else { return .location }
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
    
    func dormantStreamAlertSettingChanged(to value: Bool) {
        guard networkChecker.connectionAvailable else {
            self.alert = InAppAlerts.noInternetConnection()
            return
        }
        dormantAlert = value
        controller.changeDormantAlertSettings(to: value) { result in
            switch result {
            case .success():
                DispatchQueue.main.async {
                    self.userSettings.dormantSessionsAlert = value
                }
            case .failure(let error):
                Log.error("Failed to change dormant alert settings: \(error)")
                DispatchQueue.main.async {
                    self.userSettings.dormantSessionsAlert = !value
                    self.dormantAlert = !value
                    self.alert = InAppAlerts.failedDormantStreamSettingAlert()
                }
            }
        }
    }
}
