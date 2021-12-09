// Created by Lunar on 17/11/2021.
//

import Foundation
import CoreBluetooth
import Combine

enum SDCardSessionType: CaseIterable {
    case mobile, fixed, cellular
}

struct SDCardSyncProgess {
    let sessionType: SDCardSessionType
    let progress: SDCardProgress
}

class SDSyncController: ObservableObject {
    private let fileWriter: SDSyncFileWriter
    private let airbeamServices: SDCardAirBeamServices
    private let fileValidator: SDSyncFileValidator
    private let mobileSessionsSaver: SDCardMobileSessionssSaver
    private let averagingService: AveragingService
    private let sessionSynchronizer: SessionSynchronizer
    private let writingQueue = DispatchQueue(label: "SDSyncController")
    
    init(airbeamServices: SDCardAirBeamServices, fileWriter: SDSyncFileWriter, fileValidator: SDSyncFileValidator, mobileSessionsSaver: SDCardMobileSessionssSaver, averagingService: AveragingService, sessionSynchronizer: SessionSynchronizer) {
        self.airbeamServices = airbeamServices
        self.fileWriter = fileWriter
        self.fileValidator = fileValidator
        self.mobileSessionsSaver = mobileSessionsSaver
        self.averagingService = averagingService
        self.sessionSynchronizer = sessionSynchronizer
    }
    
    func syncFromAirbeam(_ airbeamConnection: CBPeripheral, progress: @escaping (SDCardSyncProgess) -> Void, completion: @escaping (Bool) -> Void) {
        guard let sensorName = airbeamConnection.name else {
            Log.error("Unable to identify the device")
            completion(false)
            return
        }

        airbeamServices.downloadData(from: airbeamConnection, progress: { [weak self] chunk in
            // Filesystem write
            self?.writingQueue.async {
                self?.fileWriter.writeToFile(data: chunk.payload, sessionType: chunk.sessionType)
                progress(.init(sessionType: chunk.sessionType, progress: chunk.progress))
            }
        }, completion: { [weak self] result in
            guard let self = self else { return }
            self.writingQueue.sync {
                switch result {
                case .success(let metadata):
                    let files = self.fileWriter.finishAndSave()
                    self.checkFilesForCorruption(files, expectedMeasurementsCount: metadata.expectedMeasurementsCount)
                    //TODO: Continue processing SD card data when files are not corrupted. Return an error and finish sync without clearing sd card if they are.
                    if let mobileFileURL = files.first(where: { $0.1 == SDCardSessionType.mobile })?.0 {
                        self.mobileSessionsSaver.saveDataToDb(fileURL: mobileFileURL, deviceID: sensorName) { result in
                            switch result {
                            case .success(let sessions):
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
                    } else {
                        completion(true)
                    }
                case .failure: self.fileWriter.finishAndRemoveFiles(); completion(false)
                }
            }
        })
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
    
    private func checkFilesForCorruption(_ files: [(URL, SDCardSessionType)], expectedMeasurementsCount: [SDCardSessionType: Int]) {
        let toValidate = files.map { file -> (URL, SDCardSessionType, Int) in
            let fileURL = file.0
            let sessionType = file.1
            let expectedMeasurementsCount = expectedMeasurementsCount[sessionType] ?? 0
            return (fileURL, sessionType, expectedMeasurementsCount)
        }
        self.fileValidator.validate(files: toValidate, completion: { _ in })
    }
}
