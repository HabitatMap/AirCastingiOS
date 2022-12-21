// Created by Lunar on 06/12/2021.
//
import Foundation

enum ClearingSDCardError {
    case undefined
    case noConnection
    case noClearing
}

protocol ClearingSDCardViewModel: ObservableObject {
    var isClearingCompleted: Published<Bool>.Publisher { get }
    var shouldDismiss: Published<Bool>.Publisher { get }
    var presentNextScreen: Bool { get set }
    var isSDClearProcess: Bool { get set }
    var alert: AlertInfo? { get set }
    func clearSDCardButtonTapped()
}

import SwiftUI
import Resolver

// [RESOLVER] Move this VM init to view afte all dependencies are resolved
class ClearingSDCardViewModelDefault: ClearingSDCardViewModel, ObservableObject {
    var shouldDismiss: Published<Bool>.Publisher { $shouldDismissValue }
    var isClearingCompleted: Published<Bool>.Publisher { $isClearingCompletedValue }

    var isSDClearProcess: Bool
    private let device: any BluetoothDevice
    @Injected private var airBeamConnectionController: AirBeamConnectionController
    @Injected private var sdSyncController: SDSyncController
    private var error = ClearingSDCardError.undefined
    @Published var alert: AlertInfo?
    @Published private var isClearingCompletedValue: Bool = false
    @Published private var shouldDismissValue: Bool = false
    @Published var presentNextScreen: Bool = false
    
    
    init(isSDClearProcess: Bool, device: any BluetoothDevice) {
        self.isSDClearProcess = isSDClearProcess
        self.device = device
    }
    
    func clearSDCardButtonTapped() {
        self.airBeamConnectionController.connectToAirBeam(device: device) { result in
            guard result == .success else {
                DispatchQueue.main.async {
                    self.isClearingCompletedValue = false
                    self.error = ClearingSDCardError.noConnection
                    self.getAlert()
                }
                return
            }
            self.sdSyncController.clearSDCard(self.device) { result in
                self.airBeamConnectionController.disconnectAirBeam(device: self.device)
                DispatchQueue.main.async {
                    self.isClearingCompletedValue = result
                    self.presentNextScreen = result
                    if !result {
                        self.error = ClearingSDCardError.noClearing
                        self.getAlert()
                    }
                }
            }
        }
    }
    
    private func getAlert() {
        switch error {
        case .undefined:
            alert = InAppAlerts.failedSDClearingBasicAlert { self.dismissView() }
        case .noConnection:
            alert = InAppAlerts.connectionTimeoutAlert { self.dismissView() }
        case .noClearing:
            alert = InAppAlerts.failedSDClearingBasicAlert { self.dismissView() }
        }
    }
    
    private func dismissView() {
        shouldDismissValue = true
    }
}
