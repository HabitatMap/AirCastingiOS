// Created by Lunar on 17/11/2021.
//

import Foundation
import CoreBluetooth

enum SDCardSessionType: CaseIterable {
    case mobile, fixed, cellular
}

class SDSyncController: ObservableObject {
    private let fileWriter: SDSyncFileWriter
    private let airbeamServices: SDCardAirBeamServices
    private let fileValidator: SDSyncFileValidator
    private let mobileSessionsSaver: SDCardMobileSessionssSaver
    private let writingQueue = DispatchQueue(label: "SDSyncController")
    private var metadata: [SDCardMetaData] = []
    
    init(airbeamServices: SDCardAirBeamServices, fileWriter: SDSyncFileWriter, fileValidator: SDSyncFileValidator, mobileSessionsSaver: SDCardMobileSessionssSaver) {
        self.airbeamServices = airbeamServices
        self.fileWriter = fileWriter
        self.fileValidator = fileValidator
        self.mobileSessionsSaver = mobileSessionsSaver
    }
    
    func syncFromAirbeam(_ airbeamConnection: CBPeripheral, completion: @escaping (Bool) -> Void) {
        metadata = []
        airbeamServices.downloadData(from: airbeamConnection, progress: { [weak self] data in
            switch data {
            case .chunk(let chunk):
                // Filesystem write
                self?.writingQueue.async {
                    self?.fileWriter.writeToFile(data: chunk.payload, sessionType: chunk.sessionType)
                }
            case .metadata(let metaData):
                self?.metadata.append(metaData)
            }
        }, completion: { [weak self] result in
            guard let self = self else { return }
            self.writingQueue.sync {
                switch result {
                case .success:
                    let files = self.fileWriter.finishAndSave()
                    self.checkFilesForCorruption(files)
                    //TODO: Continue processing SD card data when files are not corrupted. Return an error and finish sync without clreating sd card if they are.
                    if let mobileFileURL = files.first(where: { $0.1 == SDCardSessionType.mobile })?.0 {
                        self.mobileSessionsSaver.saveDataToDb(fileURL: mobileFileURL)
                    }
                    completion(true)
                case .failure: self.fileWriter.finishAndRemoveFiles(); completion(false)
                }
            }
        })
    }
    
    func checkFilesForCorruption(_ files: [(URL, SDCardSessionType)]) {
        let toValidate = files.map { file -> (URL, SDCardSessionType, Int) in
            let fileURL = file.0
            let sessionType = file.1
            let expectedMeasurementsCount = self.metadata.first(where: { $0.sessionType == file.1 })!.measurementsCount
            return (fileURL, sessionType, expectedMeasurementsCount)
        }
        self.fileValidator.validate(files: toValidate, completion: { _ in })
    }
}
