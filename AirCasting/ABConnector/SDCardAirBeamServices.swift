// Created by Lunar on 17/11/2021.
//

import CoreMIDI
import Combine
import Resolver

enum SDCardSyncError: Error {
    case cantDecodePayload
    case wrongOrderOfReceivedPayload
    case unexpectedMetadataFormat
    case failedConfiguration
    case airbeamDisconnected
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
    func downloadData(from device: any BluetoothDevice, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void)
    func clearSDCard(of device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
}

class BluetoothSDCardAirBeamServices: SDCardAirBeamServices, BluetoothConnectionObserver {
    private let singleChunkMeasurementsCount = Constants.SDCardSync.numberOfMeasurementsInDataChunk
    // has notifications about measurements count in particular csv file on SD card
    private let DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID = CharacteristicUUID(value:"0000ffde-0000-1000-8000-00805f9b34fb")
    
    // has notifications for reading measurements stored in csv files on SD card
    private let DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID = CharacteristicUUID(value:"0000ffdf-0000-1000-8000-00805f9b34fb")
    
    @Injected private var bluetoothManager: BluetoothCommunicator
    @Injected private var bluetoothConnection: BluetoothConnectionObservable
    private var dataCharacteristicObserver: AnyHashable?
    private var metadataCharacteristicObserver: AnyHashable?
    private var clearCardCharacteristicObserver: AnyHashable?
    
    private var expectedMeasurementsCount: [SDCardSessionType: Int] = [:]
    private var receivedMeasurementsCount: [SDCardSessionType: Int] = [:]
    private var monitoringForFinishedSendingToken: Cancellable?
    private let queue: DispatchQueue = .init(label: "SDSyncAirBeamServices")
    private var currentDevice: (any BluetoothDevice)?
    private var completion: ((Result<SDCardDownloadSummary, Error>) -> Void)?
    
    init() {
        bluetoothConnection.addConnectionObserver(self)
    }
    
    deinit {
        bluetoothConnection.removeConnectionObserver(self)
    }
    
    func didDisconnect(device: any BluetoothDevice) {
        guard device.uuid == currentDevice?.uuid else { return }
        self.finishSync(device: device) { completion?(.failure(SDCardSyncError.airbeamDisconnected)) }
    }
    
    func downloadData(from device: any BluetoothDevice, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void) {
        currentDevice = device
        self.completion = completion
        // It is imporatant here that we sunscribe to characteristic before configuring the AB because AB starts sending data immediately after receiving the config
        self.subscribeForDownloadingData(device: device, progress: progress, completion: completion)
        configureABforSync(device: device) { result in
            switch result {
            case .success():
                Log.info("Successfully configured AB for sd sync")
            case .failure(let error):
                Log.error("Failed to configure AirBeam for downloading data from SD card: \(error)")
                self.queue.async { [weak self] in
                    Log.warning("[SD SYNC] Finishing sync")
                    self?.finishSync(device: device) { completion(.failure(SDCardSyncError.failedConfiguration)) }
                }
            }
        }
    }
    
    func clearSDCard(of device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        Log.info("[SD Sync] Starting clearing SD card process")
        // It is imporatant here that we sunscribe to characteristic before configuring the AB because AB starts sending data immediately after receiving the config
        self.subscribeToMetaDataForClearingCard(device: device, completion: completion)
        sendClearConfig(device: device) { result in
            switch result {
            case .success():
                Log.info("Successfully configured AB for clearing sd card")
            case .failure(let error):
                Log.error("Failed to configure AirBeam for clearing SD card: \(error)")
                self.queue.async { [weak self] in
                    Log.warning("[SD SYNC] Finishing sync")
                    self?.finishSync(device: device) { completion(.failure(SDCardSyncError.failedConfiguration)) }
                }
            }
        }
    }
    
    private func subscribeForDownloadingData(device: any BluetoothDevice, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void) {
        var currentSessionType: SDCardSessionType?
        Log.info("[SD Sync] Downloading data")
        do {
            Log.warning("Subscribe to bluettoth metadata with characteristics: \(self.DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID) ")
            metadataCharacteristicObserver = try bluetoothManager.subscribeToCharacteristic(for: device, characteristic: DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
                switch result {
                case .success(let data):
                    self.queue.async { [weak self] in
                        currentSessionType = currentSessionType.next
                        self?.handleMetadata(data, device: device, currentSessionType: currentSessionType!, completion: completion)
                    }
                case .failure(let error):
                    self.queue.async { [weak self] in
                        self?.finishSync(device: device) { completion(.failure(error)) }
                    }
                }
            }
            Log.warning("Subscribe to bluettoth data with characteristics: \(self.DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID) ")
            dataCharacteristicObserver = try bluetoothManager.subscribeToCharacteristic(for: device, characteristic: DOWNLOAD_FROM_SD_CARD_CHARACTERISTIC_UUID) { result in
                switch result {
                case .success(let data):
                    Log.warning("MARTA: data success outside queue, data: \(String(describing: String(data: data!, encoding: .utf8)))")
                    self.queue.async { [weak self] in
                        self?.handlePayload(device: device, data: data, currentSessionType: currentSessionType, progress: progress, completion: completion)
                    }
                case .failure(let error):
                    self.queue.async { [weak self] in
                        self?.finishSync(device: device) { completion(.failure(error)) }
                    }
                }
            }
        } catch {
            Log.error("Failed to sunscribe to characteristics: \(error)")
        }
    }
    
    private func subscribeToMetaDataForClearingCard(device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            Log.warning("Subscribe to bluettoth clearing with characteristics: \(self.DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID) ")
            clearCardCharacteristicObserver = try bluetoothManager.subscribeToCharacteristic(for: device, characteristic: DOWNLOAD_META_DATA_FROM_SD_CARD_CHARACTERISTIC_UUID, timeout: 10) { result in
                switch result {
                case .success(let data):
                    guard let data = data, let payload = String(data: data, encoding: .utf8) else {
                        completion(.failure(SDCardSyncError.cantDecodePayload))
                        self.bluetoothManager.unsubscribeCharacteristicObserver(token: self.clearCardCharacteristicObserver!)
                        return
                    }
                    Log.info("[SD CARD SYNC] " + payload)
                    if payload == "SD_DELETE_FINISH" {
                        completion(.success(()))
                        Log.info("[SD CARD SYNC] SD card cleared")
                        self.bluetoothManager.unsubscribeCharacteristicObserver(token: self.clearCardCharacteristicObserver!)
                    } else {
                        Log.warning("[SD CARD SYNC] Wrong metadata for clearing sd card")
                        self.bluetoothManager.unsubscribeCharacteristicObserver(token: self.clearCardCharacteristicObserver!)
                    }
                case .failure(let error):
                    Log.warning("Error while receiving metadata from SD card: \(error.localizedDescription)")
                    completion(.failure(error))
                    self.bluetoothManager.unsubscribeCharacteristicObserver(token: self.clearCardCharacteristicObserver!)
                }
            }
        } catch {
            Log.error("Failed to sunscribe to characteristics: \(error)")
        }
    }
    
    private func handleMetadata(_ data: Data?, device: any BluetoothDevice, currentSessionType: SDCardSessionType, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void) {
        guard let data = data, let payload = String(data: data, encoding: .utf8) else {
            self.finishSync(device: device) { completion(.failure(SDCardSyncError.cantDecodePayload)) }
            return
        }
        
        Log.info("[SD CARD SYNC] Metadata: " + payload)
        if payload == "SD_SYNC_FINISH" {
            // It is possible that when Airbeam is pluged in and the data is sent faster than iPhone can process, we receive this SD_SYNC_FINISH message before all of the payload is sent.
            // That's why we have to add the monitoring which checks if any new data is still being send, and if not, then we are letting the called know that Airbeam finished sending data.
            Log.info("[SD Sync] Received SD_SYNC_FINISH message. Monitoring for end of payload.")
            self.startMonitoringForEnd {
                self.finishSync(device: device) { completion(.success(.init(expectedMeasurementsCount: self.expectedMeasurementsCount))) }
                Log.info("[SD CARD SYNC] Sync finished.")
            }
            return
        }
        
        // This is needed for showing progress in the view
        // Payload format is ` Some string: ${number_of_entries_expected} `
        guard let measurementsCountSting = payload.split(separator: ":").last?.trimmingCharacters(in: .whitespaces) else {
            Log.warning("Unexpected metadata format: (\(payload))")
            self.finishSync(device: device) { completion(.failure(SDCardSyncError.unexpectedMetadataFormat)) }
            return
        }
        let measurementsCount = Int(measurementsCountSting)
        
        /* It can happen, that in the given airbeam some type of session was never recorded. In that case, metadata format will be different
         and in that case we want to set currentSessionTypeExpected to 0 */
        self.expectedMeasurementsCount[currentSessionType] = measurementsCount ?? 0
    }
    
    private func handlePayload(device: any BluetoothDevice, data: Data?, currentSessionType: SDCardSessionType?, progress: @escaping (SDCardDataChunk) -> Void, completion: @escaping (Result<SDCardDownloadSummary, Error>) -> Void) {
        guard let data = data, let payload = String(data: data, encoding: .utf8) else { return }
        guard let sessionType = currentSessionType else {
            Log.error("[SD SYNC] Received data before first metadata payload!")
            self.finishSync(device: device) { completion(.failure(SDCardSyncError.wrongOrderOfReceivedPayload)) }
            return
        }
        
        Log.warning("Handling payload \(payload) with measurenemts count ???")
        let numberOfMeasurementsInChunk =  payload.components(separatedBy: "\r\n").filter { !$0.trimmingCharacters(in: ["\n"]).isEmpty }.count
        /// It's not ALWAYS 4, right? What for smaller payloads?
        self.receivedMeasurementsCount[sessionType, default: 0] += numberOfMeasurementsInChunk
        
        guard let expectedMeasurementsCount = self.expectedMeasurementsCount[sessionType], expectedMeasurementsCount != 0 else {
            Log.error("[SD SYNC] Received data for session type which should have 0 measurements")
            return
        }
        
        
        /// Why like this?
        let receivedMeasurementsNumber = self.receivedMeasurementsCount[sessionType]! < expectedMeasurementsCount ? self.receivedMeasurementsCount[sessionType]! : expectedMeasurementsCount
        let progressFraction = SDCardProgress(received: receivedMeasurementsNumber, expected: expectedMeasurementsCount)
        progress(SDCardDataChunk(payload: payload, sessionType: sessionType, progress: progressFraction))
    }
    
    private func configureABforSync(device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        let configurator = Resolver.resolve(AirBeamConfigurator.self, args: device)
        configurator.configureSDSync(completion: completion)
    }
    
    private func sendClearConfig(device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        let configurator = Resolver.resolve(AirBeamConfigurator.self, args: device)
        configurator.clearSDCard(completion: completion)
    }
    
    private func finishSync(device: any BluetoothDevice, completion: () -> Void) {
        self.bluetoothManager.unsubscribeCharacteristicObserver(token: self.dataCharacteristicObserver!)
        self.bluetoothManager.unsubscribeCharacteristicObserver(token: self.metadataCharacteristicObserver!)
        expectedMeasurementsCount = [:]
        receivedMeasurementsCount = [:]
        currentDevice = nil
        if let token = monitoringForFinishedSendingToken {
            token.cancel()
        }
        completion()
    }
    
    private func startMonitoringForEnd(completion: @escaping () -> Void) -> Void {
        guard !allMeasurementsDownloaded() else { completion(); return }
        
        var checkedMeasurementsCount: [SDCardSessionType: Int] = [:]
        monitoringForFinishedSendingToken = queue.schedule(after: queue.now, interval: .seconds(1)) {
            
            Log.debug("Checking measurements count with:\n expected \(self.expectedMeasurementsCount)\n received \(self.receivedMeasurementsCount)\n checked \(checkedMeasurementsCount)")
            
            guard checkedMeasurementsCount != self.receivedMeasurementsCount else {
                Log.debug("NO NEW MEASUREMENT IN 1 SEC")
                completion()
                return
            }
            checkedMeasurementsCount = self.receivedMeasurementsCount
            guard !self.allMeasurementsDownloaded() else {
                Log.info("All measurements downloaded")
                completion(); return
            }
        }
    }
    
    private func allMeasurementsDownloaded() -> Bool {
        Log.warning("Monitoring for end of payload, expected: \(self.expectedMeasurementsCount), received: \(self.receivedMeasurementsCount)")
        return receivedMeasurementsCount.allSatisfy( { $1 >= expectedMeasurementsCount[$0] ?? 0 })
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
