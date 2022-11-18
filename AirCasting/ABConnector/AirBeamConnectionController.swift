// Created by Lunar on 30/07/2021.
//

import Foundation
import Resolver

protocol AirBeamConnectionController {
    func connectToAirBeam(device: NewBluetoothManager.BluetoothDevice, completion: @escaping (AirBeamServicesConnectionResult) -> Void)
    func disconnectAirBeam(device: NewBluetoothManager.BluetoothDevice)
}

class DefaultAirBeamConnectionController: AirBeamConnectionController {
    @Injected private var connectingAirBeamServices: ConnectingAirBeamServices
    
    func connectToAirBeam(device: NewBluetoothManager.BluetoothDevice, completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        connectingAirBeamServices.connect(to: device, timeout: 10, completion: completion)
    }
    
    func disconnectAirBeam(device: NewBluetoothManager.BluetoothDevice) {
        connectingAirBeamServices.disconnect(from: device)
    }
}
