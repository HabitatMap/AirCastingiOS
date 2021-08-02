// Created by Lunar on 30/07/2021.
//

import Foundation
import CoreBluetooth

protocol AirBeamConnectionController {
    func connectToAirBeam(peripheral: CBPeripheral, completion: @escaping (Bool) -> Void)
}

class DefaultAirBeamConnectionController: AirBeamConnectionController, ObservableObject {
    let connectingAirBeamServices: ConnectingAirBeamServices
    func connectToAirBeam(peripheral: CBPeripheral, completion: @escaping (Bool) -> Void) {
        connectingAirBeamServices.connect(to: peripheral, timeout: 10) { result in
            switch result {
            case .success:
                completion(true)
            case .deviceBusy, .timeout:
                completion(false)
            }
        }
    }
    
    init(connectingAirBeamServices: ConnectingAirBeamServices) {
        self.connectingAirBeamServices = connectingAirBeamServices
    }
}

#if DEBUG
struct DummyAirBeamConnectionController: AirBeamConnectionController {
    func connectToAirBeam(peripheral: CBPeripheral, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}
#endif
