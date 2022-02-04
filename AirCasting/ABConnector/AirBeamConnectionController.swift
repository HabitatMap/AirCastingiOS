// Created by Lunar on 30/07/2021.
//

import Foundation
import CoreBluetooth
import Resolver

protocol AirBeamConnectionController {
    func connectToAirBeam(peripheral: CBPeripheral, completion: @escaping (Bool) -> Void)
    func disconnectAirBeam(peripheral: CBPeripheral)
}

class DefaultAirBeamConnectionController: AirBeamConnectionController {
    @Injected private var connectingAirBeamServices: ConnectingAirBeamServices
    
    func connectToAirBeam(peripheral: CBPeripheral, completion: @escaping (Bool) -> Void) {
        connectingAirBeamServices.connect(to: peripheral, timeout: 10) { result in
            switch result {
            case .success:
                completion(true)
            case .deviceBusy:
                completion(false)
            case .timeout:
                completion(false)
            }
        }
    }
    
    func disconnectAirBeam(peripheral: CBPeripheral) {
        connectingAirBeamServices.disconnect(from: peripheral)
    }
}
