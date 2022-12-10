// Created by Lunar on 30/07/2021.
//

import Foundation
import Resolver

protocol AirBeamConnectionController {
    func connectToAirBeam(device: any BluetoothDevice, completion: @escaping (AirBeamServicesConnectionResult) -> Void)
    func disconnectAirBeam(device: any BluetoothDevice)
}

class DefaultAirBeamConnectionController: AirBeamConnectionController {
    @Injected private var connectingAirBeamServices: ConnectingAirBeamServices
    
    func connectToAirBeam(device: any BluetoothDevice, completion: @escaping (AirBeamServicesConnectionResult) -> Void) {
        connectingAirBeamServices.connect(to: device, timeout: 10, completion: completion)
    }
    
    func disconnectAirBeam(device: any BluetoothDevice) {
        connectingAirBeamServices.disconnect(from: device)
    }
}
