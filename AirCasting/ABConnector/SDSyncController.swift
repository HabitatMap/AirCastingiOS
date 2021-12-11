// Created by Lunar on 17/11/2021.
//

import Foundation
import CoreBluetooth
import Combine

enum SDCardSessionType: CaseIterable {
    case mobile, fixed, cellular
}

struct SDCardSyncProgress {
    let sessionType: SDCardSessionType
    let progress: SDCardProgress
}

enum SDCardSyncStatus {
    case inProgress(SDCardSyncProgress)
    case finalizing
}

class SDSyncController: ObservableObject {
    private let fileWriter: SDSyncFileWriter
    private let airbeamServices: SDCardAirBeamServices
    private let fileValidator: SDSyncFileValidator
    private let fileLineReader: FileLineReader
    private let mobileSessionsSaver: SDCardMobileSessionssSaver
    private let fixedSessionsSaver: SDCardFixedSessionsSavingService
    private let averagingService: AveragingService
    private let sessionSynchronizer: SessionSynchronizer
    private let writingQueue = DispatchQueue(label: "SDSyncController")
    
    init(airbeamServices: SDCardAirBeamServices, fileWriter: SDSyncFileWriter, fileValidator: SDSyncFileValidator, fileLineReader: FileLineReader, mobileSessionsSaver: SDCardMobileSessionssSaver, fixedSessionsSaver: SDCardFixedSessionsSavingService, averagingService: AveragingService, sessionSynchronizer: SessionSynchronizer) {
        self.airbeamServices = airbeamServices
        self.fileWriter = fileWriter
        self.fileValidator = fileValidator
        self.fileLineReader = fileLineReader
        self.mobileSessionsSaver = mobileSessionsSaver
        self.fixedSessionsSaver = fixedSessionsSaver
        self.averagingService = averagingService
        self.sessionSynchronizer = sessionSynchronizer
    }
    
    func syncFromAirbeam(_ airbeamConnection: CBPeripheral, progress: @escaping (SDCardSyncStatus) -> Void, completion: @escaping (Bool) -> Void) {
        guard let sensorName = airbeamConnection.name else {
            Log.error("[SD Sync] Unable to identify the device")
            completion(false)
            return
        }

        airbeamServices.downloadData(from: airbeamConnection, progress: { [weak self] chunk in
            // Filesystem write
            self?.writingQueue.async {
                self?.fileWriter.writeToFile(data: chunk.payload, sessionType: chunk.sessionType)
                progress(.inProgress(.init(sessionType: chunk.sessionType, progress: chunk.progress)))
            }
        }, completion: { [weak self] result in
            guard let self = self else { return }
            self.writingQueue.sync {
                switch result {
                case .success(let metadata):
                    progress(.finalizing)
                    let files = self.fileWriter.finishAndSave()
                    self.checkFilesForCorruption(files, expectedMeasurementsCount: metadata.expectedMeasurementsCount) { result in
                        switch result {
                        case .success:
                            self.handle(files: files, deviceID: sensorName, completion: completion)
                        case .failure(let error):
                            Log.error("[SD Sync] File corrupted: \(error)")
                            completion(false)
                        }
                    }
                case .failure:
                    self.fileWriter.finishAndRemoveFiles()
                    completion(false)
                }
            }
        })
    }
    
    private func handle(files: [(URL, SDCardSessionType)], deviceID: String, completion: @escaping (Bool) -> Void ) {
        let mobileFileURL = files.first(where: { $0.1 == SDCardSessionType.mobile })?.0
        let fixedFileURL = files.first(where: { $0.1 == SDCardSessionType.fixed })?.0
        
        func handleFixedFile(fixedFileURL: URL) {
            do {
                try self.process(fixedSessionFile: fixedFileURL, deviceID: deviceID, completion: completion)
            } catch {
                completion(false)
            }
        }
        
        if let mobileFileURL = mobileFileURL {
            process(mobileSessionFile: mobileFileURL, deviceID: deviceID) { mobileResult in
                guard mobileResult else {
                    completion(mobileResult)
                    return
                }
                
                if let fixedFileURL = fixedFileURL {
                    handleFixedFile(fixedFileURL: fixedFileURL)
                }
            }
        } else if let fixedFileURL = fixedFileURL {
            handleFixedFile(fixedFileURL: fixedFileURL)
        } else {
            completion(true)
        }
    }
    
    private func process(fixedSessionFile: URL, deviceID: String, completion: @escaping (Bool) -> Void) throws {
        let csvSession = try CSVSession(fileURL: fixedSessionFile,
                                        fileLineReader: fileLineReader)
        fixedSessionsSaver.processAndSync(csvSession: csvSession, deviceID: deviceID, completion: completion)
    }
    
    private func process(mobileSessionFile: URL, deviceID: String, completion: @escaping (Bool) -> Void) {
        do {
            self.mobileSessionsSaver.saveDataToDb(fileURL: mobileSessionFile, deviceID: deviceID) { result in
                switch result {
                case .success(let sessions):
                    self.averagingService.averageMeasurements(for: sessions) {
                        Log.info("[SD Sync] Averaging done")
                        self.onCurrentSyncEnd { self.startBackendSync() }
                    }
                    completion(true)
                case .failure(let error):
                    Log.error("[SD Sync] Failed to save sessions to database: \(error.localizedDescription)")
                    completion(false)
                }
            }
        } catch {
            completion(false)
        }
    }
    
    func clearSDCard(_ airbeamConnection: CBPeripheral, completion: @escaping (Bool) -> Void) {
        airbeamServices.clearSDCard(of: airbeamConnection) { result in
            switch result {
            case .success():
                completion(true)
            case .failure(let error):
                Log.error(error.localizedDescription)
                completion(false)
            }
        }
    }
    
    private func startBackendSync() {
        sessionSynchronizer.triggerSynchronization()
    }
    
    private func onCurrentSyncEnd(_ completion: @escaping () -> Void) {
        guard sessionSynchronizer.syncInProgress.value else { completion(); return }
        var cancellable: AnyCancellable?
        cancellable = sessionSynchronizer.syncInProgress.sink { syncInProgress in
            guard !syncInProgress else { return }
            completion()
            cancellable?.cancel()
        }
    }
    
    private func checkFilesForCorruption(_ files: [(URL, SDCardSessionType)], expectedMeasurementsCount: [SDCardSessionType: Int], completion: (Result<[(URL, SDCardSessionType)], Error>) -> Void) {
        let toValidate = files.map { file -> (URL, SDCardSessionType, Int) in
            let fileURL = file.0
            let sessionType = file.1
            let expectedMeasurementsCount = expectedMeasurementsCount[sessionType] ?? 0
            return (fileURL, sessionType, expectedMeasurementsCount)
        }
        
        self.fileValidator.validate(files: toValidate) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(files))
            }
        }
    }
}
