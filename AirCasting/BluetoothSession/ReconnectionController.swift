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
        guard mobilePeripheralManager.activeSessionInProgressWith(device.peripheral) else { return } // TODO: Move away from CB!
        mobilePeripheralManager.markActiveSessionAsDisconnected(peripheral: device.peripheral)
        bluetootConnector.connect(to: device, timeout: 10) { result in
            switch result {
            case .success:
                Log.info("Reconnected to a peripheral: \(device.peripheral)")
                self.bluetootConnector.discoverCharacteristics(for: device, timeout: 10) { result in
                    switch result {
                    case .success:
                        Log.info("Discovered characteristics for: \(device.peripheral)")
                        self.mobilePeripheralManager.configureAB()
                    case .failure(_):
                        self.mobilePeripheralManager.moveSessionToStandaloneMode(peripheral: device.peripheral)
                    }
                }
            case .failure(_):
                self.mobilePeripheralManager.moveSessionToStandaloneMode(peripheral: device.peripheral)
            }
        }
    }
}
