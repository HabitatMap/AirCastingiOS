// Created by Lunar on 17/11/2021.
//

import CoreBluetooth
import CoreMIDI
import Combine
import Resolver

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
    
    @Injected private var bluetoothManager: BluetoothManager
    private var dataCharacteristicObserver: AnyHashable?
    private var metadataCharacteristicObserver: AnyHashable?
    private var clearCardCharacteristicObserver: AnyHashable?
    
    private var expectedMeasurementsCount: [SDCardSessionType: Int] = [:]
    private var receivedMeasurementsCount: [SDCardSessionType: Int] = [:]
    private var monitoringForFinishedSendingToken: Cancellable?
    private let queue: DispatchQueue = .init(label: "SDSyncAirBeamServices")
    
    func downloadData(from peripheral: CBPeripheral, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void) {
        var currentSessionType: SDCardSessionType?
        
        Log.info("[SD Sync] Downloading data")
        
        configureABforSync(peripheral: peripheral)
        metadataCharacteristicObserver = bluetoothManager.subscribeToCharacteristic(DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                self.queue.async { [weak self] in
                    currentSessionType = currentSessionType.next
                    self?.handleMetadata(data, currentSessionType: currentSessionType!, completion: completion)
                }
            case .failure(let error):
                self.queue.async { [weak self] in
                    Log.warning("[SD SYNC]  Error while receiving metadata from SD card: \(error.localizedDescription)")
                    self?.finishSync { completion(.failure(error)) }
                }
            }
        }
        
        dataCharacteristicObserver = bluetoothManager.subscribeToCharacteristic(DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
            switch result {
            case .success(let data):
                self.queue.async { [weak self] in
                    self?.handlePayload(data: data, currentSessionType: currentSessionType, progress: progress, completion: completion)
                }
            case .failure(let error):
                self.queue.async { [weak self] in
                    Log.warning("Error while receiving data from SD card: \(error.localizedDescription)")
                    self?.finishSync { completion(.failure(error)) }
                }
            }
        }
    }
    
    func clearSDCard(of peripheral: CBPeripheral, completion: @escaping (Result<Void, Error>) -> Void) {
        Log.info("[SD Sync] Starting clearing SD card process")
        sendClearConfig(peripheral: peripheral)
        clearCardCharacteristicObserver = bluetoothManager.subscribeToCharacteristic(DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID, timeout: 10) { result in
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
    
    private func handleMetadata(_ data: Data?, currentSessionType: SDCardSessionType, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void) {
        guard let data = data, let payload = String(data: data, encoding: .utf8) else {
            self.finishSync { completion(.failure(SDCardSyncError.cantDecodePayload)) }
            return
        }
        
        Log.info("[SD CARD SYNC] " + payload)
        if payload == "SD_SYNC_FINISH" {
            // It is possible that when Airbeam is pluged in and the data is sent faster than iPhone can process, we receive this SD_SYNC_FINISH message before all of the payload is sent.
            // That's why we have to add the monitoring which checks if any new data is still being send, and if not, then we are letting the called know that Airbeam finished sending data.
            Log.info("[SD Sync] Received SD_SYNC_FINISH message. Monitoring for end of payload.")
            self.startMonitoringForEnd {
                self.finishSync { completion(.success(.init(expectedMeasurementsCount: self.expectedMeasurementsCount))) }
                Log.info("[SD CARD SYNC] Sync finished.")
            }
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
        self.expectedMeasurementsCount[currentSessionType] = measurementsCount ?? 0
    }
    
    private func handlePayload(data: Data?, currentSessionType: SDCardSessionType?, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void) {
        guard let data = data, let payload = String(data: data, encoding: .utf8) else { return }
        guard let sessionType = currentSessionType else {
            Log.error("[SD SYNC] Received data before first metadata payload!")
            self.finishSync { completion(.failure(SDCardSyncError.wrongOrderOfReceivedPayload)) }
            return
        }
        self.receivedMeasurementsCount[sessionType, default: 0] += Constants.SDCardSync.numberOfMeasurementsInDataChunk
        
        guard let expectedMeasurementsCount = self.expectedMeasurementsCount[sessionType], expectedMeasurementsCount != 0 else {
            Log.error("[SD SYNC] Received data for session type which should have 0 measurements")
            return
        }
        
        let receivedMeasurementsNumber = self.receivedMeasurementsCount[sessionType]! < expectedMeasurementsCount ? self.receivedMeasurementsCount[sessionType]! : expectedMeasurementsCount
        let progressFraction = SDCardProgress(received: receivedMeasurementsNumber, expected: expectedMeasurementsCount)
        progress(SDCardDataChunk(payload: payload, sessionType: sessionType, progress: progressFraction))
    }
    
    private func configureABforSync(peripheral: CBPeripheral) {
        let configurator = AirBeam3Configurator(peripheral: peripheral)
        configurator.configureSDSync()
    }
    
    private func sendClearConfig(peripheral: CBPeripheral) {
        let configurator = AirBeam3Configurator(peripheral: peripheral)
        configurator.clearSDCard()
    }
    
    private func finishSync(completion: () -> Void) {
        self.bluetoothManager.unsubscribeCharacteristicObserver(self.dataCharacteristicObserver!)
        self.bluetoothManager.unsubscribeCharacteristicObserver(self.metadataCharacteristicObserver!)
        expectedMeasurementsCount = [:]
        receivedMeasurementsCount = [:]
        if let token = monitoringForFinishedSendingToken {
            token.cancel()
        }
        completion()
    }
    
    private func startMonitoringForEnd(completion: @escaping () -> Void) -> Void {
        var checkedMeasurementsCount: [SDCardSessionType: Int] = [:]

        monitoringForFinishedSendingToken = queue.schedule(after: queue.now, interval: .seconds(1)) {
            Log.debug("Checking with:\n expected \(self.expectedMeasurementsCount)\n received \(self.receivedMeasurementsCount)\n checked \(checkedMeasurementsCount)")
            guard checkedMeasurementsCount != self.receivedMeasurementsCount else {
                Log.debug("NO NEW MEASUREMENT IN 1 SEC")
                completion()
                return
            }
            checkedMeasurementsCount = self.receivedMeasurementsCount
            for receivedMeasurementsForSessionType in self.receivedMeasurementsCount {
                if self.expectedMeasurementsCount[receivedMeasurementsForSessionType.key] ?? 0 < receivedMeasurementsForSessionType.value {
                    Log.info("All measurements downloaded")
                    completion(); return
                }
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
        case .some(.cellular): return .cellular
        }
    }
}
