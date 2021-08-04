// Created by Lunar on 21/07/2021.
//

import Foundation
import CoreBluetooth

class ConnectingABViewModel: ObservableObject {
    @Published var shouldDismiss: Bool = false
    @Published var isDeviceConnected: Bool = false
    private let airBeamConnectionController: AirBeamConnectionController
    
    init(airBeamConnectionController: AirBeamConnectionController) {
        self.airBeamConnectionController = airBeamConnectionController
    }
    
    func connectToAirBeam(peripheral: CBPeripheral) {
        self.airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { success in
            self.isDeviceConnected = success
            self.shouldDismiss = !success
        }
    }
}
