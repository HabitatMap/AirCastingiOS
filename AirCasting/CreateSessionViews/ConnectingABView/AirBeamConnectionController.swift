// Created by Lunar on 30/07/2021.
//

import Foundation
import CoreBluetooth

enum AirBeamConnectionState {
    case connected
    case connecting
    case disconnected
}

protocol AirBeamConnectionController {
    var connectionState: AirBeamConnectionState { get }
    func connectToAirBeam(peripheral: CBPeripheral, completion: @escaping (Bool) -> Void)
}

class DefaultAirBeamConnectionController: AirBeamConnectionController, ObservableObject {
    let connectingAirBeamServices: ConnectingAirBeamServices
    private(set) var connectionState: AirBeamConnectionState
    
    func connectToAirBeam(peripheral: CBPeripheral, completion: @escaping (Bool) -> Void) {
        self.connectionState = .connecting
        connectingAirBeamServices.connect(to: peripheral, timeout: 10) { [weak self, connectingAirBeamServices] result in
            self?.connectionState = Self.determineConnectionState(using: connectingAirBeamServices)
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
    
    init(connectingAirBeamServices: ConnectingAirBeamServices) {
        self.connectingAirBeamServices = connectingAirBeamServices
        self.connectionState = Self.determineConnectionState(using: connectingAirBeamServices)
    }
    
    private static func determineConnectionState(using services: ConnectingAirBeamServices) -> AirBeamConnectionState {
        if services.connectionInProgress { return .connecting }
        if services.isAirbeamConnected { return .connected }
        return .disconnected
    }
}

#if DEBUG
struct DummyAirBeamConnectionController: AirBeamConnectionController {
    var connectionState: AirBeamConnectionState = .connecting
    func connectToAirBeam(peripheral: CBPeripheral, completion: @escaping (Bool) -> Void) {
        completion(true)
    }
}
#endif
