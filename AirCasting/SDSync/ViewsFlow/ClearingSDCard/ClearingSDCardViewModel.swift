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
    func clearSDCard()
    func getAlertTitle() -> String
    func getAlertMessage() -> String
}

class ClearingSDCardViewModelDefault: ClearingSDCardViewModel, ObservableObject {
    var shouldDismiss: Published<Bool>.Publisher { $shouldDismissValue }
    var isClearingCompleted: Published<Bool>.Publisher { $isClearingCompletedValue }

    var isSDClearProcess: Bool
    private let userAuthenticationSession: UserAuthenticationSession
    private let peripheral: CBPeripheral
    private let airBeamConnectionController: AirBeamConnectionController
    private let sdSyncController: SDSyncController
    private var error = ClearingSDCardError.undefined
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
    
    func clearSDCard() {
        self.airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { success in
            guard success else {
                DispatchQueue.main.async {
                    self.isClearingCompletedValue = false
                    self.shouldDismissValue = true
                    self.error = ClearingSDCardError.noConnection
                }
                return
            }
            self.sendClearConfig()
            self.sdSyncController.clearSDCard(self.peripheral) { result in
                DispatchQueue.main.async {
                    self.isClearingCompletedValue = result
                    self.shouldDismissValue = !result
                    if !result {
                        self.error = ClearingSDCardError.noClearing
                    }
                }
            }
        }
    }
    
    func getAlertTitle() -> String {
        switch error {
        case .undefined:
            return Strings.ClearingSDCardView.failedClearingAlertTitle
        case .noConnection:
            return Strings.AirBeamConnector.connectionTimeoutTitle
        case .noClearing:
            return Strings.ClearingSDCardView.failedClearingAlertTitle
        }
    }
    
    func getAlertMessage() -> String {
        switch error {
        case .undefined:
            return Strings.ClearingSDCardView.failedClearingAlertMessage
        case .noConnection:
            return Strings.AirBeamConnector.connectionTimeoutDescription
        case .noClearing:
            return Strings.ClearingSDCardView.failedClearingAlertMessage
        }
    }
    
    private func sendClearConfig() {
        let configurator = AirBeam3Configurator(userAuthenticationSession: self.userAuthenticationSession,
                                                peripheral: self.peripheral)
        configurator.clearSDCard()
    }
}
