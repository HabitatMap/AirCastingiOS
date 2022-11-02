// Created by Lunar on 30/07/2021.
//

import Foundation
import Resolver

protocol AirBeamConnectionController {
    func connectToAirBeam(device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Bool) -> Void)
    func disconnectAirBeam(device: NewBluetoothManager.BluetoothDevice)
}

class DefaultAirBeamConnectionController: AirBeamConnectionController {
    @Injected private var connectingAirBeamServices: ConnectingAirBeamServices
    
    func connectToAirBeam(device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Bool) -> Void) {
        connectingAirBeamServices.connect(to: device, timeout: 10) { result in
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
    
    func disconnectAirBeam(device: NewBluetoothManager.BluetoothDevice) {
        connectingAirBeamServices.disconnect(from: device)
    }
}
