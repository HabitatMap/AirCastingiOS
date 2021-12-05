// Created by Lunar on 17/11/2021.
//

import CoreBluetooth
import CoreMIDI

enum SDCardSyncError: Error {
    case cantDecodePayload
    case wrongOrderOfReceivedPayload
    case unexpectedMetadataFormat
}

struct SDCardDataChunk {
    let payload: String
    let sessionType: SDCardSessionType
    let progress: Double
}

struct SDCardDownloadSummary {
    let expectedMeasurementsCount: [SDCardSessionType: Int]
}

protocol SDCardAirBeamServices {
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void)
}

class BluetoothSDCardAirBeamServices: SDCardAirBeamServices {
    private let singleChunkMeasurementsCount = Constants.SDCardSync.numberOfMeasurementsInDataChunk
    // has notifications about measurements count in particular csv file on SD card
    private let DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    
    // has notifications for reading measurements stored in csv files on SD card
    private let DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffdf-0000-1000-8000-00805f9b34fb")
    
    private let bluetoothCommunicator: BluetoothCommunicator
    
    private var dataCharacteristicObserver: AnyHashable?
    private var metadataCharacteristicObserver: AnyHashable?
    
    init(bluetoothCommunicator: BluetoothCommunicator) {
        self.bluetoothCommunicator = bluetoothCommunicator
    }
    
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void) {
        var expectedMeasurementsCount: [SDCardSessionType: Int] = [:]
        var receivedMeasurementsCount: [SDCardSessionType: Int] = [:]
        var currentSessionType: SDCardSessionType?
        metadataCharacteristicObserver = bluetoothCommunicator.subscribeToCharacteristic(DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                guard let data = data, let payload = String(data: data, encoding: .utf8) else {
                    self.finishSync { completion(.failure(SDCardSyncError.cantDecodePayload)) }
                    return
                }
                currentSessionType = currentSessionType.next
                Log.info("[SD CARD SYNC] " + payload)
                if payload == "SD_SYNC_FINISH" {
                    self.finishSync { completion(.success(.init(expectedMeasurementsCount: expectedMeasurementsCount))) }
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
                expectedMeasurementsCount[currentSessionType!] = measurementsCount ?? 0
            case .failure(let error):
                Log.warning("Error while receiving metadata from SD card: \(error.localizedDescription)")
                self.finishSync { completion(.failure(error)) }
            }
        }
        
        dataCharacteristicObserver = bluetoothCommunicator.subscribeToCharacteristic(DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                guard let data = data, let payload = String(data: data, encoding: .utf8) else { return }
                guard let sessionType = currentSessionType else {
                    Log.error("Received data before first metadata payload!")
                    self.finishSync { completion(.failure(SDCardSyncError.wrongOrderOfReceivedPayload)) }
                    return
                }
                receivedMeasurementsCount[sessionType, default: 0] += 1
                let progressFraction = Double(receivedMeasurementsCount[sessionType]!) / Double(expectedMeasurementsCount[sessionType].orOne)
                progress(SDCardDataChunk(payload: payload, sessionType: sessionType, progress: progressFraction))

            case .failure(let error):
                Log.warning("Error while receiving data from SD card: \(error.localizedDescription)")
                self.finishSync { completion(.failure(error)) }
            }
        }
    }
    
    func finishSync(completion: () -> Void) {
        self.bluetoothCommunicator.unsubscribeCharacteristicObserver(self.dataCharacteristicObserver!)
        self.bluetoothCommunicator.unsubscribeCharacteristicObserver(self.metadataCharacteristicObserver!)
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
