// Created by Lunar on 02/12/2021.
//

import Foundation
import Resolver

enum ProceedToSyncView {
    case locationDenied
    case restart
    case bluetooth
}

protocol BackendSyncCompletedViewModel: ObservableObject {
    var presentRestartNextScreen: Bool { get }
    var presentBTNextScreen: Bool { get }
    var presentLocationNextScreen: Bool { get }
    func continueButtonTapped()
}

class BackendSyncCompletedViewModelDefault: BackendSyncCompletedViewModel, ObservableObject {
    
    @Published var presentRestartNextScreen: Bool = false
    @Published var presentBTNextScreen: Bool = false
    @Published var presentLocationNextScreen: Bool = false
    @Injected private var bluetoothHandler: BluetoothPermisionsChecker
    @Injected private var locationAuthorization: LocationAuthorization
    
    func continueButtonTapped() {
        switch sessionNextStep() {
        case .locationDenied: proceedToLocationScreen()
        case .bluetooth: proceedToBTScreen()
        case .restart: proceedToRestartScreen()
        }
    }
    
    private func proceedToBTScreen() { presentBTNextScreen.toggle() }
    
    private func proceedToRestartScreen() { presentRestartNextScreen.toggle() }
    
    private func proceedToLocationScreen() { presentLocationNextScreen.toggle() }
    
    private func sessionNextStep() -> ProceedToSyncView {
        guard locationAuthorization.locationState == .granted else { return .locationDenied }
        guard !bluetoothHandler.isBluetoothDenied() else { return .bluetooth }
        return .restart
    }
}
