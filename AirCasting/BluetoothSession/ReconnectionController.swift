// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver

class ReconnectionController: BluetoothConnectionObserver {
    @Injected private var mobilePeripheralManager: MobilePeripheralSessionManager
    @Injected private var bluetoothManager: BluetoothConnectionObservable
    @Injected private var bluetootConnector: BluetoothConnectionHandler
    
    init() {
        bluetoothManager.addConnectionObserver(self)
    }
    
    deinit {
        bluetoothManager.removeConnectionObserver(self)
    }
    
    func didDisconnect(device: NewBluetoothManager.BluetoothDevice) {
        guard mobilePeripheralManager.activeSessionInProgressWith(device) else { return }
        mobilePeripheralManager.markActiveSessionAsDisconnected(device: device)
        bluetootConnector.connect(to: device, timeout: 10) { result in
            switch result {
            case .success:
                Log.info("Reconnected to a peripheral: \(device)")
                self.bluetootConnector.discoverCharacteristics(for: device, timeout: 10) { result in
                    switch result {
                    case .success:
                        Log.info("Discovered characteristics for: \(device)")
                        self.mobilePeripheralManager.configureAB()
                    case .failure(_):
                        self.mobilePeripheralManager.moveSessionToStandaloneMode(device: device)
                    }
                }
            case .failure(_):
                self.mobilePeripheralManager.moveSessionToStandaloneMode(device: device)
            }
        }
    }
}
