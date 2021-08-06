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
    
    init(airBeamConnectionController: AirBeamConnectionController, peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.airBeamConnectionController = airBeamConnectionController
    }
    
    func connectToAirBeam() {
        self.airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { success in
            self.isDeviceConnectedValue = success
            self.shouldDismissValue = !success
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
