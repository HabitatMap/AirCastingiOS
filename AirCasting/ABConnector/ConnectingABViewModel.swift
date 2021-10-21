// Created by Lunar on 21/07/2021.
//

import Combine
import CoreBluetooth

protocol AirbeamConnectionViewModel: ObservableObject {
    var shouldDismiss: Published<Bool>.Publisher { get }
    var isDeviceConnected: Published<Bool>.Publisher { get }
    func connectToAirBeam()
}

class AirbeamConnectionViewModelDefault: AirbeamConnectionViewModel, ObservableObject {
    var shouldDismiss: Published<Bool>.Publisher { $shouldDismissValue }
    var isDeviceConnected: Published<Bool>.Publisher { $isDeviceConnectedValue }
    
    @Published private var shouldDismissValue: Bool = false
    @Published private var isDeviceConnectedValue: Bool = false
    
    private let peripheral: CBPeripheral
    private let airBeamConnectionController: AirBeamConnectionController
    private let userAuthenticationSession: UserAuthenticationSession
    private let sessionContext: CreateSessionContext
    
    init(airBeamConnectionController: AirBeamConnectionController,
         userAuthenticationSession: UserAuthenticationSession,
         sessionContext: CreateSessionContext,
         peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.airBeamConnectionController = airBeamConnectionController
        self.userAuthenticationSession = userAuthenticationSession
        self.sessionContext = sessionContext
    }
    
    func connectToAirBeam() {
        self.airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { success in
            self.isDeviceConnectedValue = success
            self.shouldDismissValue = !success
            
            if success {
                self.configureABToFixed()
            }
        }
    }
    
    private func configureABToFixed() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            if let sessionUUID = self.sessionContext.sessionUUID,
               self.sessionContext.sessionType == .fixed {
                let configurator =
                AirBeam3Configurator(userAuthenticationSession: self.userAuthenticationSession,
                                     peripheral: self.peripheral)
                do {
                    try configurator.configureFixed(uuid: sessionUUID)
                } catch {
                    Log.info("Couldn't configure AB to fixed session with uuid: \(sessionUUID)")
                }
            }
        }
    }
}

class NeverConnectingAirbeamConnectionViewModel: AirbeamConnectionViewModel {
    var shouldDismiss: Published<Bool>.Publisher { $shouldDismissValue }
    var isDeviceConnected: Published<Bool>.Publisher { $isDeviceConnectedValue }
    
    @Published private var shouldDismissValue: Bool = false
    @Published private var isDeviceConnectedValue: Bool = false
    
    func connectToAirBeam() { }
}
