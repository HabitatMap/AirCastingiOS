// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver

protocol ReconnectionControllerDelegate: AnyObject {
    func shouldReconnect(to device: any BluetoothDevice) -> Bool
    func didReconnect(to device: any BluetoothDevice)
    func didFailToReconnect(to device: any BluetoothDevice)
}

protocol ReconnectionController {
    var delegate: ReconnectionControllerDelegate? { get set }
}

class DefaultReconnectionController: ReconnectionController, BluetoothConnectionObserver {
    weak var delegate: ReconnectionControllerDelegate?
    @Injected private var bluetoothManager: BluetoothConnectionObservable
    @Injected private var bluetootConnector: BluetoothConnectionHandler
    
    init() {
        bluetoothManager.addConnectionObserver(self)
    }
    
    deinit {
        bluetoothManager.removeConnectionObserver(self)
    }
    
    func didDisconnect(device: any BluetoothDevice) {
        guard delegate?.shouldReconnect(to: device) ?? false else { return }
        
        do {
            try bluetootConnector.connect(to: device, timeout: 10) { result in
                switch result {
                case .success:
                    Log.info("Reconnected to a peripheral: \(device)")
                    do {
                        try self.bluetootConnector.discoverCharacteristics(for: device, timeout: 10) { result in
                            switch result {
                            case .success:
                                Log.info("Discovered characteristics for: \(device)")
                                self.delegate?.didReconnect(to: device)
                            case .failure(_):
                                self.delegate?.didFailToReconnect(to: device)
                            }
                        }
                    } catch {
                        Log.error("Faild to reconnect: \(error)")
                        self.delegate?.didFailToReconnect(to: device)
                    }
                case .failure(_):
                    self.delegate?.didFailToReconnect(to: device)
                }
            }
        } catch {
            Log.error("Faild to reconnect: \(error)")
        }
    }
}
