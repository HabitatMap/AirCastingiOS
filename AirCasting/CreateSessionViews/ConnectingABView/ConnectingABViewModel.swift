// Created by Lunar on 21/07/2021.
//

import SwiftUI
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
            if success {
                self.isDeviceConnected = true
            } else {
                self.isDeviceConnected = false
                self.shouldDismiss = true
            }
        }
    }
}
