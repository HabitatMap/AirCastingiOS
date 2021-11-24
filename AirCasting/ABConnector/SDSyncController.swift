// Created by Lunar on 17/11/2021.
//

import Foundation
import CoreBluetooth

enum SDCardSessionType: CaseIterable {
    case mobile, fixed, cellular
}

enum SDCardValidationError: Error {
    case insufficientIntegrity
}

protocol SDSyncFileValidator {
    func validate(files: [(URL, SDCardSessionType, expectedMeasurementsCount: Int)], completion: (Result<Void, SDCardValidationError>) -> Void)
}

class SDSyncController: ObservableObject {
    private let fileWriter: SDSyncFileWriter
    private let airbeamServices: SDCardAirBeamServices
    private let fileValidator: SDSyncFileValidator
    private let writingQueue = DispatchQueue(label: "SDSyncController")
    private var metadata: [SDCardMetaData] = []
    
    init(airbeamServices: SDCardAirBeamServices, fileWriter: SDSyncFileWriter, fileValidator: SDSyncFileValidator) {
        self.airbeamServices = airbeamServices
        self.fileWriter = fileWriter
        self.fileValidator = fileValidator
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
                    let files = self.fileWriter.finishAndSave(); completion(true)
                    let toValidate = files.map { file in (file.0, file.1, self.metadata.first(where: { $0.sessionType == file.1 })!.measurementsCount) }
                    self.fileValidator.validate(files: toValidate, completion: { _ in })
                case .failure: self.fileWriter.finishAndRemoveFiles(); completion(false)
                }
            }
        })
    }
}
