// Created by Lunar on 17/11/2021.
//

import CoreBluetooth
import CoreMIDI

enum SDCardSessionType {
    case mobile, fixed, cellular
}

struct SDCardDataChunk {
    let payload: String // Ten nasz characteristic (z Data do String)
    let sessionType: SDCardSessionType
}

protocol SDCardAirBeamServices {
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<Void, Error>) -> Void)
}

class BluetoothSDCardAirBeamServices: SDCardAirBeamServices {
    private let singleChunkMeasurementsCount = 4
    // has notifications about measurements count in particular csv file on SD card
    private let DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    
    // has notifications for reading measurements stored in csv files on SD card
    private let DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffdf-0000-1000-8000-00805f9b34fb")
    
    private let bluetoothManager: BluetoothManager
    
    private var currentSessionType: SDCardSessionType?
    private var currentSessionTypeReceived: Int = 0
    private var currentSessionTypeExpected: Int = 0
    
    private var dataCharacteristicObserver: AnyHashable?
    private var metadataCharacteristicObserver: AnyHashable?
    
    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
    }
    
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        metadataCharacteristicObserver = bluetoothManager.subscribeToCharacteristic(DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                guard let data = data, let payload = String(data: data, encoding: .utf8) else { return }
                self.currentSessionType = self.currentSessionType.next
                // Payload format is ` Some string: ${number_of_entries_expected} `
                guard let measurementsCountSting = payload.split(separator: ":").last?.trimmingCharacters(in: .whitespaces),
                      let measurementsCount = Int(measurementsCountSting) else {
                    Log.warning("Unexpected metadata format: (\(payload))")
                    return
                }
                self.currentSessionTypeExpected = measurementsCount
                
                if self.currentSessionType == .cellular && measurementsCount == 0 {
                    completion(.success(()))
                    self.bluetoothManager.unsubscribeCharacteristicObserver(self.dataCharacteristicObserver!)
                    self.bluetoothManager.unsubscribeCharacteristicObserver(self.metadataCharacteristicObserver!)
                }
            case .failure(let error):
                Log.warning("Error while receiving metadata from SD card: \(error.localizedDescription)")
                completion(.failure(error))
                self.bluetoothManager.unsubscribeCharacteristicObserver(self.dataCharacteristicObserver!)
                self.bluetoothManager.unsubscribeCharacteristicObserver(self.metadataCharacteristicObserver!)
            }
        }
        
        dataCharacteristicObserver = bluetoothManager.subscribeToCharacteristic(DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                guard let data = data, let payload = String(data: data, encoding: .utf8) else { return }
                guard let sessionType = self.currentSessionType else {
                    Log.error("Received data before first metadata payload!")
                    return
                }
                progress(SDCardDataChunk(payload: payload, sessionType: sessionType))
                
                if self.currentSessionType == .cellular && self.currentSessionTypeExpected >= self.currentSessionTypeReceived {
                    completion(.success(()))
                    self.bluetoothManager.unsubscribeCharacteristicObserver(self.dataCharacteristicObserver!)
                    self.bluetoothManager.unsubscribeCharacteristicObserver(self.metadataCharacteristicObserver!)
                } else {
                    self.currentSessionTypeReceived += self.singleChunkMeasurementsCount
                }
            case .failure(let error):
                Log.warning("Error while receiving data from SD card: \(error.localizedDescription)")
                completion(.failure(error))
                self.bluetoothManager.unsubscribeCharacteristicObserver(self.dataCharacteristicObserver!)
                self.bluetoothManager.unsubscribeCharacteristicObserver(self.metadataCharacteristicObserver!)
            }
            
        }
    }
}

extension Optional where Wrapped == SDCardSessionType {
    var next: Wrapped {
        switch self {
        case .none: return .mobile
        case .some(.mobile): return .fixed
        case .some(.fixed): return .cellular
        case .some(.cellular):
            Log.error("Tried to increment from .cellular for SDCardSessionType")
            return .cellular
        }
    }
}
