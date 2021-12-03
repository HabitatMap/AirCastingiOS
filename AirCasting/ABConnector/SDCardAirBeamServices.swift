// Created by Lunar on 17/11/2021.
//

import CoreBluetooth
import CoreMIDI

enum SDCardData {
    case chunk(SDCardDataChunk)
    case metadata(SDCardMetaData)
}

enum SDCardSyncError: Error {
    case cantDecodePayload
    case wrongOrderOfReceivedPayload
    case unexpectedMetadataFormat
}

struct SDCardDataChunk {
    let payload: String
    let sessionType: SDCardSessionType
}

struct SDCardMetaData {
    let sessionType: SDCardSessionType
    let measurementsCount: Int
}

protocol SDCardAirBeamServices {
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardData) -> Void, completion: @escaping (Result<Void, Error>) -> Void)
}

class BluetoothSDCardAirBeamServices: SDCardAirBeamServices {
    private let singleChunkMeasurementsCount = Constants.SDCardSync.numberOfMeasurementsInDataChunk
    // has notifications about measurements count in particular csv file on SD card
    private let DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    
    // has notifications for reading measurements stored in csv files on SD card
    private let DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffdf-0000-1000-8000-00805f9b34fb")
    
    private let bluetoothManager: BluetoothManager
    
    private var dataCharacteristicObserver: AnyHashable?
    private var metadataCharacteristicObserver: AnyHashable?
    
    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager
    }
    
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardData) -> Void, completion: @escaping (Result<Void, Error>) -> Void) {
        var currentSessionType: SDCardSessionType?
        var currentSessionTypeReceived: Int = 0
        var currentSessionTypeExpected: Int = 0
        metadataCharacteristicObserver = bluetoothManager.subscribeToCharacteristic(DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                guard let data = data, let payload = String(data: data, encoding: .utf8) else {
                    self.finishSync { completion(.failure(SDCardSyncError.cantDecodePayload)) }
                    return
                }
                currentSessionType = currentSessionType.next
                Log.info("[SD CARD SYNC] " + payload)
                if payload == "SD_SYNC_FINISH" {
                    self.finishSync { completion(.success(())) }
                    Log.info("[SD CARD SYNC] Sync finished.")
                    return
                }
                
                // This will be needed when we will want to show progress in the view
                // Payload format is ` Some string: ${number_of_entries_expected} `
                guard let measurementsCountSting = payload.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) else {
                          Log.warning("Unexpected metadata format: (\(payload))")
                          self.finishSync { completion(.failure(SDCardSyncError.unexpectedMetadataFormat)) }
                          return
                      }
                let measurementsCount = Int(measurementsCountSting)
                
                /* It can happen, that in the given airbeam some type of session was never recorded. In that case, metadata format will be different
                 and in that case we want to set currentSessionTypeExpected to 0 */
                currentSessionTypeExpected = measurementsCount ?? 0
                
                progress(.metadata(SDCardMetaData(sessionType: currentSessionType!, measurementsCount: currentSessionTypeExpected)))
            case .failure(let error):
                Log.warning("Error while receiving metadata from SD card: \(error.localizedDescription)")
                self.finishSync { completion(.failure(error)) }
            }
        }
        
        dataCharacteristicObserver = bluetoothManager.subscribeToCharacteristic(DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                guard let data = data, let payload = String(data: data, encoding: .utf8) else { return }
                guard let sessionType = currentSessionType else {
                    Log.error("Received data before first metadata payload!")
                    self.finishSync { completion(.failure(SDCardSyncError.wrongOrderOfReceivedPayload)) }
                    return
                }
                progress(.chunk(SDCardDataChunk(payload: payload, sessionType: sessionType)))
                

            case .failure(let error):
                Log.warning("Error while receiving data from SD card: \(error.localizedDescription)")
                self.finishSync { completion(.failure(error)) }
            }
        }
    }
    
    func finishSync(completion: () -> Void) {
        self.bluetoothManager.unsubscribeCharacteristicObserver(self.dataCharacteristicObserver!)
        self.bluetoothManager.unsubscribeCharacteristicObserver(self.metadataCharacteristicObserver!)
        completion()
    }
}

extension Optional where Wrapped == SDCardSessionType {
    var next: Wrapped {
        switch self {
        case .none: return .mobile
        case .some(.mobile): return .fixed
        case .some(.fixed): return .cellular
        case .some(.cellular): return .cellular
        }
    }
}
