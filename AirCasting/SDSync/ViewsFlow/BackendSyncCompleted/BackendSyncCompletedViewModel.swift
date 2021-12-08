// Created by Lunar on 02/12/2021.
//

import Foundation

enum ProceedToSyncView {
    case restart
    case bluetooth
}

protocol BackendSyncCompletedViewModel: ObservableObject {
    var presentRestartNextScreen: Bool { get set }
    var presentBTNextScreen: Bool { get set }
    var urlProvider: BaseURLProvider { get }
    func procedToBTScreen()
    func procedToRestartScreen()
    func sessionNextStep() -> ProceedToSyncView
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
    
    func procedToBTScreen() { presentBTNextScreen.toggle() }
    
    func procedToRestartScreen() { presentRestartNextScreen.toggle() }
    
    func sessionNextStep() -> ProceedToSyncView {
        guard !bluetoothHandler.isBluetoothDenied() else { return .bluetooth }
        return .restart
    }
}
