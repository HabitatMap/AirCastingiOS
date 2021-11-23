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
    
    func scanForDevices()  {

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

//extension SDSyncController: CBPeripheralDelegate {
//
//
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        if let services = peripheral.services {
//            for service in services {
//                peripheral.discoverCharacteristics(nil, for: service)
//            }
//        }
//    }
//
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        var hasSomeCharacteristics = false
//        if let characteristics = service.characteristics {
//
//        }
//        hasSomeCharacteristics ? NotificationCenter.default.post(name: .discoveredCharacteristic, object: nil, userInfo: [AirCastingNotificationKeys.DiscoveredCharacteristic.peripheralUUID : peripheral.identifier]) : nil
//    }
//
//    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        guard let value = characteristic.value else {
//            Log.warning("AirBeam sent measurement without value")
//            return
//        }
//    }
//}
