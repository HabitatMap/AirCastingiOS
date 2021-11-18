// Created by Lunar on 16/11/2021.
//

import Foundation
import CoreBluetooth

class SDSyncController: ObservableObject {
    let bluetoothManager: BluetoothManager
    let userAuthenticationSession: UserAuthenticationSession
    let connectingAirBeamServicesBluetooth: ConnectingAirBeamServicesBluetooth
    
    init(bluetoothManager: BluetoothManager, userAuthenticationSession: UserAuthenticationSession) {
        self.bluetoothManager = bluetoothManager
        self.userAuthenticationSession = userAuthenticationSession
        connectingAirBeamServicesBluetooth = ConnectingAirBeamServicesBluetooth(bluetoothConnector: bluetoothManager)
    }
    
    func triggerDownloadingData() {
        Log.info("## Downloading data triggered")
//        guard let airbeam = bluetoothManager.airbeams.first else { return }
//        connectingAirBeamServicesBluetooth.connect(to: airbeam, timeout: 5, completion: { result in
//            switch result {
//            case .success:
//                Log.info("SUCCESS")
//            case .timeout:
//                Log.info("TIME OUT")
//            case .deviceBusy:
//                Log.info("DEVICE BUSY")
//            }
//        })
        
    }
}

