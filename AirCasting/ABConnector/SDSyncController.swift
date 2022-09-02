// Created by Lunar on 17/11/2021.
//

import Foundation
import CoreBluetooth
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
    @Injected private var fileValidator: SDSyncFileValidator
    @Injected private var fileLineReader: FileLineReader
    @Injected private var mobileSessionsSaver: SDCardMobileSessionssSaver
    @Injected private var fixedSessionsUploader: SDCardFixedSessionsUploadingService
    @Injected private var averagingService: AveragingService
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var measurementsDownloader: SyncedMeasurementsDownloader

    private let writingQueue = DispatchQueue(label: "SDSyncController")

    func syncFromAirbeam(_ airbeamConnection: CBPeripheral, progress: @escaping (SDCardSyncStatus) -> Void, completion: @escaping (Result<Void, SDSyncError>) -> Void) {
        Log.info("[SD SYNC] Starting syncing")
        guard let sensorName = airbeamConnection.name else {
            Log.error("[SD SYNC] Unable to identify the device")
            completion(.failure(.unidetifiableDevice))
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
                    Log.info("[SD SYNC] Finished reading data with success")
                    progress(.finalizing)
                    let files = self.fileWriter.finishAndSave()
                    Log.info("[SD SYNC] Files: \(files)")
                    guard !files.isEmpty else {
                        Log.info("[SD SYNC] No files. Finishing sd sync")
                        completion(.success(()))
                        return
                    }

                    // MARK: checking if files have the right number of rows and if rows have the right values
                    self.checkFilesForCorruption(files, expectedMeasurementsCount: metadata.expectedMeasurementsCount) { fileValidationResult in
                        switch fileValidationResult {
                        case .success(let verifiedFiles):
                            Log.info("[SD SYNC] Check for corruption passed")
                            self.handle(files: verifiedFiles, sensorName: sensorName, completion: completion)
                        case .failure(let error):
                            Log.error("File verification \(error.localizedDescription)")
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

    private func handle(files: [(URL, SDCardSessionType)], sensorName: String, completion: @escaping (Result<Void, SDSyncError>) -> Void ) {
        let mobileFileURL = files.first(where: { $0.1 == SDCardSessionType.mobile })?.0
        let fixedFileURL = files.first(where: { $0.1 == SDCardSessionType.fixed })?.0

        func handleFixedFile(fixedFileURL: URL) {
            process(fixedSessionFile: fixedFileURL, deviceID: sensorName) { result in
                switch result {
                case .success(let fixedSessionsUUIDs):
                    self.measurementsDownloader.download(sessionsUUIDs: fixedSessionsUUIDs)
                    completion(.success(()))
                case .failure:
                    completion(.failure(.fixedSessionsProcessingFailure))
                }
            }
        }

        if let mobileFileURL = mobileFileURL {
            process(mobileSessionFile: mobileFileURL, deviceID: sensorName) { mobileResult in
                guard mobileResult else {
                    completion(.failure(.mobileSessionsProcessingFailure))
                    return
                }

                if let fixedFileURL = fixedFileURL {
                    handleFixedFile(fixedFileURL: fixedFileURL)
                } else {
                    completion(.success(()))
                }
            }
        } else if let fixedFileURL = fixedFileURL {
            handleFixedFile(fixedFileURL: fixedFileURL)
        } else {
            completion(.success(()))
        }
    }

    private func process(fixedSessionFile: URL, deviceID: String, completion: @escaping (Result<[SessionUUID], Error>) -> Void) {
        Log.info("[SD Sync] Processing fixed file")
        fixedSessionsUploader.processAndUpload(fileURL: fixedSessionFile, deviceID: deviceID) { result in
            switch result {
            case .success(let sessions):
                Log.info("[SD Sync] Finished processing fixed file with success")
                completion(.success(sessions))
            case .failure(let error):
                Log.error("Failed to upload sessions to backend: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    private func process(mobileSessionFile: URL, deviceID: String, completion: @escaping (Bool) -> Void) {
        Log.info("[SD Sync] Processing mobile file")
        self.mobileSessionsSaver.saveDataToDb(fileURL: mobileSessionFile, deviceID: deviceID) { result in
            switch result {
            case .success(let sessions):
                Log.info("[SD Sync] Saved mobile data with success")
                self.averagingService.averageMeasurements(for: sessions) {
                    Log.info("Averaging done")
                    self.onCurrentSyncEnd { self.startBackendSync() }
                }
                completion(true)
            case .failure(let error):
                Log.error("Failed to save sessions to database: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    func clearSDCard(_ airbeamConnection: CBPeripheral, completion: @escaping (Bool) -> Void) {
        airbeamServices.clearSDCard(of: airbeamConnection) { result in
            switch result {
            case .success():
                completion(true)
                Log.info("Complete clearing SD card")
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

    private func checkFilesForCorruption(_ files: [(URL, SDCardSessionType)], expectedMeasurementsCount: [SDCardSessionType: Int], completion: (Result<[(URL, SDCardSessionType)], Error>) -> Void) {
        let toValidate = files.compactMap { file -> SDCardCSVFile in
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
