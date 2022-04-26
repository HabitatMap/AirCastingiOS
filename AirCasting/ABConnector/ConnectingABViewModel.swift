// Created by Lunar on 21/07/2021.
//

import Combine
import CoreBluetooth
import Resolver

protocol AirbeamConnectionViewModel: ObservableObject {
    var shouldDismiss: Published<Bool>.Publisher { get }
    var isDeviceConnected: Published<Bool>.Publisher { get }
    func connectToAirBeam()
}

// [RESOLVER] Move this VM init to View when all dependencies resolved
class AirbeamConnectionViewModelDefault: AirbeamConnectionViewModel, ObservableObject {
    var shouldDismiss: Published<Bool>.Publisher { $shouldDismissValue }
    var isDeviceConnected: Published<Bool>.Publisher { $isDeviceConnectedValue }
    
    @Published private var shouldDismissValue: Bool = false
    @Published private var isDeviceConnectedValue: Bool = false
    
    private let peripheral: CBPeripheral
    @Injected private var airBeamConnectionController: AirBeamConnectionController
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    private let sessionContext: CreateSessionContext
    
    init(sessionContext: CreateSessionContext,
         peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.sessionContext = sessionContext
    }
    
    func connectToAirBeam() {
        self.airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { success in
            self.isDeviceConnectedValue = success
            self.shouldDismissValue = !success
            
            guard success else { return }
            self.configureAB()
        }
    }
    
    private func configureAB() {
        if let sessionUUID = self.sessionContext.sessionUUID {
            //[Resolver] NOTE: Do we want configurator to be injected?
            let configurator = AirBeam3Configurator(peripheral: self.peripheral)
            do {
                try configurator.configureFixed(uuid: sessionUUID)
            } catch {
                Log.info("Couldn't configure AB to fixed session with uuid: \(sessionUUID)")
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
