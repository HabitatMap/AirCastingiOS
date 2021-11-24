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
    
    init(airbeamServices: SDCardAirBeamServices, fileWriter: SDSyncFileWriter) {
        self.airbeamServices = airbeamServices
        self.fileWriter = fileWriter
    }
    
    func syncFromAirbeam(_ airbeamConnection: CBPeripheral, completion: @escaping (Bool) -> Void) {
        airbeamServices.downloadData(from: airbeamConnection, progress: { [weak self] chunk in
            // Filesystem write
            DispatchQueue.global(qos: .userInitiated).sync {
                self?.fileWriter.writeToFile(data: chunk.payload, sessionType: chunk.sessionType)
            }
        }, completion: { [weak self] result in
            switch result {
            //TODO: we need to finish and save when all of the data is already saved to files
            case .success: self?.fileWriter.finishAndSave(); completion(true)
            case .failure: self?.fileWriter.finishAndRemoveFiles()
            }
        })
    }
}
