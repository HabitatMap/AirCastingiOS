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
    let progress: SDCardProgress
}

struct SDCardProgress {
    let received: Int
    let expected: Int
}

struct SDCardDownloadSummary {
    let expectedMeasurementsCount: [SDCardSessionType: Int]
}

protocol SDCardAirBeamServices {
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void)
    func clearSDCard(of peripheral: CBPeripheral, completion: @escaping (Result<Void, Error>) -> Void)
}

class BluetoothSDCardAirBeamServices: SDCardAirBeamServices {
    private let singleChunkMeasurementsCount = Constants.SDCardSync.numberOfMeasurementsInDataChunk
    // has notifications about measurements count in particular csv file on SD card
    private let DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffde-0000-1000-8000-00805f9b34fb")
    
    // has notifications for reading measurements stored in csv files on SD card
    private let DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID = CBUUID(string:"0000ffdf-0000-1000-8000-00805f9b34fb")
    
    private let bluetoothManager: BluetoothManager
    private let userAuthenticationSession: UserAuthenticationSession
    private var dataCharacteristicObserver: AnyHashable?
    private var metadataCharacteristicObserver: AnyHashable?
    private var clearCardCharacteristicObserver: AnyHashable?
    
    init(bluetoothManager: BluetoothManager, userAuthenticationSession: UserAuthenticationSession) {
        self.bluetoothManager = bluetoothManager
        self.userAuthenticationSession = userAuthenticationSession
    }
    
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void) {
        var expectedMeasurementsCount: [SDCardSessionType: Int] = [:]
        var receivedMeasurementsCount: [SDCardSessionType: Int] = [:]
        var currentSessionType: SDCardSessionType?
        
        configureABforSync(peripheral: peripheral)
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
        
        dataCharacteristicObserver = bluetoothManager.subscribeToCharacteristic(DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                guard let data = data, let payload = String(data: data, encoding: .utf8) else { return }
                guard let sessionType = currentSessionType else {
                    Log.error("Received data before first metadata payload!")
                    self.finishSync { completion(.failure(SDCardSyncError.wrongOrderOfReceivedPayload)) }
                    return
                }
                receivedMeasurementsCount[sessionType, default: 0] += Constants.SDCardSync.numberOfMeasurementsInDataChunk
                
                guard let expectedMeasurementsCount = expectedMeasurementsCount[sessionType], expectedMeasurementsCount != 0 else {
                    Log.error("[SD SYNC] Received data for session type which should have 0 measurements")
                    return
                }
                
                let receivedMeasurementsNumber = receivedMeasurementsCount[sessionType]! < expectedMeasurementsCount ? receivedMeasurementsCount[sessionType]! : expectedMeasurementsCount
                let progressFraction = SDCardProgress(received: receivedMeasurementsNumber, expected: expectedMeasurementsCount)
                progress(SDCardDataChunk(payload: payload, sessionType: sessionType, progress: progressFraction))

            case .failure(let error):
                Log.warning("Error while receiving data from SD card: \(error.localizedDescription)")
                self.finishSync { completion(.failure(error)) }
            }
        }
    }
    
    func clearSDCard(of peripheral: CBPeripheral, completion: @escaping (Result<Void, Error>) -> Void) {
        sendClearConfig(peripheral: peripheral)
        clearCardCharacteristicObserver = bluetoothManager.subscribeToCharacteristic(DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                guard let data = data, let payload = String(data: data, encoding: .utf8) else {
                    completion(.failure(SDCardSyncError.cantDecodePayload))
                    self.bluetoothManager.unsubscribeCharacteristicObserver(self.clearCardCharacteristicObserver!)
                    return
                }
                Log.info("[SD CARD SYNC] " + payload)
                if payload == "SD_DELETE_FINISH" {
                    completion(.success(()))
                    Log.info("[SD CARD SYNC] SD card cleared")
                    self.bluetoothManager.unsubscribeCharacteristicObserver(self.clearCardCharacteristicObserver!)
                } else {
                    Log.warning("[SD CARD SYNC] Wrong metadata for clearing sd card")
                    self.bluetoothManager.unsubscribeCharacteristicObserver(self.clearCardCharacteristicObserver!)
                }
            case .failure(let error):
                Log.warning("Error while receiving metadata from SD card: \(error.localizedDescription)")
                completion(.failure(error))
                self.bluetoothManager.unsubscribeCharacteristicObserver(self.clearCardCharacteristicObserver!)
            }
        }
    }
    
    private func configureABforSync(peripheral: CBPeripheral) {
        let configurator = AirBeam3Configurator(userAuthenticationSession: self.userAuthenticationSession,
                                                peripheral: peripheral)
        configurator.configureSDSync()
    }
    
    private func sendClearConfig(peripheral: CBPeripheral) {
        let configurator = AirBeam3Configurator(userAuthenticationSession: self.userAuthenticationSession,
                                                peripheral: peripheral)
        configurator.clearSDCard()
    }
    
    private func finishSync(completion: () -> Void) {
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
