// Created by Lunar on 02/12/2021.
//

import Foundation

enum ProceedToSyncView {
    case restart
    case bluetooth
}

protocol BackendSyncCompletedViewModel: ObservableObject {
    var presentRestartNextScreen: Bool { get }
    var presentBTNextScreen: Bool { get }
    // urlProvider should should not be exposed
    // BUT it is - REASON: it is needed only to pass to some navigation view
    var urlProvider: BaseURLProvider { get }
    func continueButtonTapped() 
}

class BackendSyncCompletedViewModelDefault: BackendSyncCompletedViewModel, ObservableObject {
    
    @Published var presentRestartNextScreen: Bool = false
    @Published var presentBTNextScreen: Bool = false
    let urlProvider: BaseURLProvider
    private let bluetoothHandler: BluetoothHandler
    
    init(urlProvider: BaseURLProvider, bluetoothHandler: BluetoothHandler) {
        self.urlProvider = urlProvider
        self.bluetoothHandler = bluetoothHandler
    }
    
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
