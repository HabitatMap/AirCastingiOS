// Created by Lunar on 06/12/2021.
//
import Foundation
import CoreBluetooth

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

class ClearingSDCardViewModelDefault: ClearingSDCardViewModel, ObservableObject {
    var shouldDismiss: Published<Bool>.Publisher { $shouldDismissValue }
    var isClearingCompleted: Published<Bool>.Publisher { $isClearingCompletedValue }

    var isSDClearProcess: Bool
    private let userAuthenticationSession: UserAuthenticationSession
    private let peripheral: CBPeripheral
    private let airBeamConnectionController: AirBeamConnectionController
    private let sdSyncController: SDSyncController
    private var error = ClearingSDCardError.undefined
    @Published var alert: AlertInfo?
    @Published private var isClearingCompletedValue: Bool = false
    @Published private var shouldDismissValue: Bool = false
    @Published var presentNextScreen: Bool = false
    
    
    init(isSDClearProcess: Bool, userAuthenticationSession: UserAuthenticationSession, peripheral: CBPeripheral, airBeamConnectionController: AirBeamConnectionController, sdSyncController: SDSyncController) {
        self.isSDClearProcess = isSDClearProcess
        self.userAuthenticationSession = userAuthenticationSession
        self.peripheral = peripheral
        self.airBeamConnectionController = airBeamConnectionController
        self.sdSyncController = sdSyncController
    }
    
    func clearSDCardButtonTapped() {
        self.airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { success in
            guard success else {
                DispatchQueue.main.async {
                    self.isClearingCompletedValue = false
                    self.error = ClearingSDCardError.noConnection
                    self.getAlert()
                }
                return
            }
            self.sdSyncController.clearSDCard(self.peripheral) { result in
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
            alert = InAppAlerts.failedSDClearingAlert(dismiss: dismissView())
        case .noConnection:
            alert = InAppAlerts.connectionTimeoutAlert(dismiss: dismissView())
        case .noClearing:
            alert = InAppAlerts.failedSDClearingAlert(dismiss: dismissView())
        }
    }
    
    private func dismissView() {
        shouldDismissValue = true
    }
}
