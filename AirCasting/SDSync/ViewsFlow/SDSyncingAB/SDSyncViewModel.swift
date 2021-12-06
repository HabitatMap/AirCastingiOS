// Created by Lunar on 21/07/2021.
//

import Combine
import CoreBluetooth

protocol SDSyncViewModel: ObservableObject {
    var shouldDismiss: Published<Bool>.Publisher { get }
    var isSyncCompleted: Published<Bool>.Publisher { get }
    var presentNextScreen: Bool { get set }
    var presentAlert: Bool { get set }
    func connectToAirBeamAndSync()
}

class SDSyncViewModelDefault: SDSyncViewModel, ObservableObject {
    
    var shouldDismiss: Published<Bool>.Publisher { $shouldDismissValue }
    var isSyncCompleted: Published<Bool>.Publisher { $isSyncCompletedValue }
    
    @Published private var shouldDismissValue: Bool = false
    @Published private var isSyncCompletedValue: Bool = false
    @Published var presentNextScreen: Bool = false
    @Published var presentAlert: Bool = false
    
    private let peripheral: CBPeripheral
    private let airBeamConnectionController: AirBeamConnectionController
    private let sdSyncController: SDSyncController
    private let userAuthenticationSession: UserAuthenticationSession
    private let sessionContext: CreateSessionContext
    
    init(airBeamConnectionController: AirBeamConnectionController,
         sdSyncController: SDSyncController,
         userAuthenticationSession: UserAuthenticationSession,
         sessionContext: CreateSessionContext,
         peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.airBeamConnectionController = airBeamConnectionController
        self.sdSyncController = sdSyncController
        self.userAuthenticationSession = userAuthenticationSession
        self.sessionContext = sessionContext
    }
    
    func connectToAirBeamAndSync() {
        self.airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { success in
            guard success else { return }
            self.configureABforSync()
            self.sdSyncController.syncFromAirbeam(self.peripheral) { result in
                //TODO: SD card should be cleared only if the files are not corrupted
                result ? self.clearSDCard() : nil
                self.disconnectAirBeam()
                DispatchQueue.main.async {
                    self.isSyncCompletedValue = result
                    self.shouldDismissValue = !result
                }
            }
        }
    }
    
    private func configureABforSync() {
        let configurator = AirBeam3Configurator(userAuthenticationSession: self.userAuthenticationSession,
                                                peripheral: self.peripheral)
        configurator.configureSDSync()
    }
    
    private func clearSDCard() {
        let configurator = AirBeam3Configurator(userAuthenticationSession: self.userAuthenticationSession,
                                                peripheral: self.peripheral)
        configurator.clearSDCard()
    }
    
    private func disconnectAirBeam() {
        airBeamConnectionController.disconnectAirBeam(peripheral: peripheral)
    }
}
