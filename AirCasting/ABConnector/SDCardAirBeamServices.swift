// Created by Lunar on 17/11/2021.
//

import CoreBluetooth

enum SDCardSessionType {
    case mobile, fixed, cellular
}

struct SDCardDataChunk {
    let payload: String // Ten nasz characteristic (z Data do String)
    let sessionType: SDCardSessionType
}

protocol SDCardAirBeamServices {
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardDataChunk) -> Void)
}

class BluetoothSDCardAirBeamServices: SDCardAirBeamServices {
    // has notifications about measurements count in particular csv file on SD card
    private let DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    
    // has notifications for reading measurements stored in csv files on SD card
    private let DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffdf-0000-1000-8000-00805f9b34fb")
    
    private let bluetoothManager: BluetoothManager
    
    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
    }
    
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardDataChunk) -> Void) {
        bluetoothManager.subscribeToCharacteristic(DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                guard let data = data, let payload = String(data: data, encoding: .utf8) else { return }
                progress(SDCardDataChunk(payload: payload, sessionType: .mobile))
            case .failure(let error):
                Log.warning("Error while receiving data from SD card: \(error.localizedDescription)")
            }
            
        }
    }
}
