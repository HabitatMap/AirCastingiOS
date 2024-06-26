// Created by Lunar on 17/11/2021.
//

import Foundation
import Combine
import Resolver

enum SDCardSessionType: CaseIterable {
    case mobile, fixed, cellular
}

struct SDCardSyncProgress {
    let sessionType: SDCardSessionType
    let progress: SDCardProgress
}

struct SDCardCSVFile {
    let url: URL
    let expectedLinesCount: Int
}

enum SDCardSyncStatus {
    case inProgress(SDCardSyncProgress)
    case finalizing
}

enum SDSyncError: Error {
    case unidetifiableDevice
    case filesCorrupted
    case readingDataFailure
    case fixedSessionsProcessingFailure
    case mobileSessionsProcessingFailure
}

class SDSyncController {
    @Injected private var fileWriter: SDSyncFileWriter
    @Injected private var airbeamServices: SDCardAirBeamServices
    @Injected private var fileLineReader: FileLineReader
    @Injected private var mobileSessionsSaver: SDCardMobileSessionssSaver
    @Injected private var fixedSessionsUploader: SDCardFixedSessionsUploadingService
    @Injected private var averagingService: ActiveSessionsAveragingController
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var measurementsDownloader: SyncedMeasurementsDownloader
    @Injected private var locationTracker: LocationTracker
    
    private let writingQueue = DispatchQueue(label: "SDSyncController")
    
    func syncFromAirbeam(_ airbeamConnection: any BluetoothDevice, progress: @escaping (SDCardSyncStatus) -> Void, completion: @escaping (Result<Void, SDSyncError>) -> Void) {
        Log.info("[SD SYNC] Starting syncing")
        guard let sensorName = airbeamConnection.name,
              let airbeamType = airbeamConnection.airbeamType else {
            Log.error("[SD SYNC] Unable to identify the device")
            completion(.failure(.unidetifiableDevice))
            return
        }

        airbeamServices.downloadData(from: airbeamConnection, progress: { [weak self] chunk in
            // Filesystem write
            let parser = Resolver.resolve(SDMeasurementsParser.self, args: sensorName)
            self?.writingQueue.async {
                self?.fileWriter.writeToFile(data: chunk.payload,
                                             parser: parser,
                                             sessionType: chunk.sessionType)
                progress(.inProgress(.init(sessionType: chunk.sessionType, progress: chunk.progress)))
            }
        }, completion: { [weak self] result in
            guard let self = self else { return }
            progress(.finalizing)
            self.writingQueue.sync {
                switch result {
                case .success(let metadata):
                    Log.info("[SD SYNC] Finished reading data with success")
                    let directories = self.fileWriter.finishAndSave()
                    Log.info("[SD SYNC] Files: \(directories)")
                    guard !directories.isEmpty else {
                        Log.info("[SD SYNC] No files. Finishing sd sync")
                        completion(.success(()))
                        return
                    }
                    
                    // MARK: checking if files have the right number of rows and if rows have the right values
                    
                    let fileValidator = Resolver.resolve(SDSyncFileValidator.self, args: airbeamType) 
                    self.checkDirectoriesForCorruption(directories, expectedMeasurementsCount: metadata.expectedMeasurementsCount, fileValidator: fileValidator) { fileValidationResult in
                        switch fileValidationResult {
                        case .success(let verifiedDirectories):
                            Log.info("[SD SYNC] Check for corruption passed")
                            self.handle(filesDirectories: verifiedDirectories, sensorName: sensorName, completion: completion)
                        case .failure(let error):
                            Log.error(error.localizedDescription)
                            completion(.failure(.filesCorrupted))
                        }
                    }
                case .failure:
                    Log.info("[SD SYNC] Reading data from AirBeam failed")
                    self.fileWriter.finishAndRemoveFiles()
                    completion(.failure(.readingDataFailure))
                }
            }
        })
    }
    
    private func handle(filesDirectories: [(URL, SDCardSessionType)], sensorName: String, completion: @escaping (Result<Void, SDSyncError>) -> Void ) {
        let mobileFilesDirectoryURL = filesDirectories.first(where: { $0.1 == SDCardSessionType.mobile })?.0
        let fixedFilesDirectoryURL = filesDirectories.first(where: { $0.1 == SDCardSessionType.fixed })?.0
        
        func handleFixedFiles(at fixedFilesDirectoryURL: URL) {
            process(fixedSessionsFilesDirectory: fixedFilesDirectoryURL, deviceID: sensorName) { result in
                switch result {
                case .success(let fixedSessionsUUIDs):
                    self.measurementsDownloader.download(sessionsUUIDs: fixedSessionsUUIDs)
                    Log.info("Completion success. Fixed sessions uploaded successfully.")
                    completion(.success(()))
                case .failure:
                    completion(.failure(.fixedSessionsProcessingFailure))
                }
            }
        }
        
        if let mobileFilesDirectoryURL = mobileFilesDirectoryURL {
            process(mobileSessionFilesDirectory: mobileFilesDirectoryURL, deviceID: sensorName) { mobileResult in
                guard mobileResult else {
                    completion(.failure(.mobileSessionsProcessingFailure))
                    return
                }
                
                if let fixedFilesDirectoryURL = fixedFilesDirectoryURL {
                    handleFixedFiles(at: fixedFilesDirectoryURL)
                } else {
                    Log.info("[SD Sync] Completion success. There was no fixed directory.")
                    completion(.success(()))
                }
            }
        } else if let fixedFilesDirectoryURL = fixedFilesDirectoryURL {
            handleFixedFiles(at: fixedFilesDirectoryURL)
        } else {
            Log.info("[SD Sync] Completion success. There were no directories.")
            completion(.success(()))
        }
    }
    
    private func process(fixedSessionsFilesDirectory: URL, deviceID: String, completion: @escaping (Result<[SessionUUID], Error>) -> Void) {
        Log.info("[SD Sync] Processing fixed file")
        fixedSessionsUploader.processAndUpload(filesDirectoryURL: fixedSessionsFilesDirectory, deviceID: deviceID) { result in
            switch result {
            case .success(let sessions):
                Log.info("[SD Sync] Finished processing fixed file with success")
                completion(.success(sessions))
            case .failure(let error):
                Log.error("[SD Sync] Failed to upload sessions to backend: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    private func process(mobileSessionFilesDirectory: URL, deviceID: String, completion: @escaping (Bool) -> Void) {
        Log.info("[SD Sync] Processing mobile file")
        Task {
            let location = try await locationTracker.oneTimeLocationUpdate()
            self.mobileSessionsSaver.saveDataToDb(filesDirectoryURL: mobileSessionFilesDirectory, deviceID: deviceID, deviceLocation: .init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)) { result in
                switch result {
                case .success():
                    Log.info("[SD Sync] Saved mobile data with success")
                    self.onCurrentSyncEnd { self.startBackendSync() }
                    completion(true)
                case .failure(let error):
                    Log.error("[SD Sync] Failed to save sessions to database: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    func clearSDCard(_ airbeamConnection: any BluetoothDevice, completion: @escaping (Bool) -> Void) {
        airbeamServices.clearSDCard(of: airbeamConnection) { result in
            switch result {
            case .success():
                completion(true)
            case .failure(let error):
                Log.error("Failed to clear SD card: \(error.localizedDescription)")
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
    
    private func checkDirectoriesForCorruption(_ directories: [(URL, SDCardSessionType)], expectedMeasurementsCount: [SDCardSessionType: Int], fileValidator: SDSyncFileValidator, completion: (Result<[(URL, SDCardSessionType)], Error>) -> Void) {
        let toValidate = directories.compactMap { file -> SDCardCSVFile in
            let fileURL = file.0
            let sessionType = file.1
            
            if sessionType == .mobile {
                return .init(url: fileURL, expectedLinesCount: expectedMeasurementsCount[.mobile] ?? 0)
            } else {
                let expectedFixed = expectedMeasurementsCount[.fixed] ?? 0
                let expectedCellular = expectedMeasurementsCount[.cellular] ?? 0
                return .init(url: fileURL, expectedLinesCount: expectedFixed + expectedCellular)
            }
        }
        
        fileValidator.validate(files: toValidate) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(directories))
            }
        }
    }
}
