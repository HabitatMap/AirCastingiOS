// Created by Lunar on 02/12/2021.
//

import Foundation
import Resolver

enum ProceedToSyncView {
    case restart
    case bluetooth
}

protocol BackendSyncCompletedViewModel: ObservableObject {
    var presentRestartNextScreen: Bool { get }
    var presentBTNextScreen: Bool { get }
    func continueButtonTapped() 
}

class BackendSyncCompletedViewModelDefault: BackendSyncCompletedViewModel, ObservableObject {
    
    @Published var presentRestartNextScreen: Bool = false
    @Published var presentBTNextScreen: Bool = false
    @Injected private var bluetoothHandler: BluetoothPermisionsChecker
    
    func continueButtonTapped() {
        switch sessionNextStep() {
        case .bluetooth: procedToBTScreen()
        case .restart: procedToRestartScreen()
        }
    }
    
    private func procedToBTScreen() { presentBTNextScreen.toggle() }
    
    private func procedToRestartScreen() { presentRestartNextScreen.toggle() }
    
    private func sessionNextStep() -> ProceedToSyncView {
        guard !bluetoothHandler.isBluetoothDenied() else { return .bluetooth }
        return .restart
    }
}
