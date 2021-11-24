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
    private let writingQueue = DispatchQueue(label: "SDSyncController")
    
    init(airbeamServices: SDCardAirBeamServices, fileWriter: SDSyncFileWriter) {
        self.airbeamServices = airbeamServices
        self.fileWriter = fileWriter
    }
    
    func syncFromAirbeam(_ airbeamConnection: CBPeripheral, completion: @escaping (Bool) -> Void) {
        airbeamServices.downloadData(from: airbeamConnection, progress: { [weak self] data in
            switch data {
            case .chunk(let chunk):
                // Filesystem write
                self?.writingQueue.async {
                    self?.fileWriter.writeToFile(data: chunk.payload, sessionType: chunk.sessionType)
                }
            case .metadata(let metaData):
                break
            }
        }, completion: { [weak self] result in
            self?.writingQueue.sync {
                switch result {
                case .success: self?.fileWriter.finishAndSave(); completion(true)
                case .failure: self?.fileWriter.finishAndRemoveFiles(); completion(false)
                }
            }
        })
    }
}
