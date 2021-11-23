// Created by Lunar on 17/11/2021.
//

import Foundation
import CoreBluetooth

class SDSyncController: ObservableObject {
    private let fileWriter: SDSyncFileWriter
    private let airbeamServices: SDCardAirBeamServices
//    private let airbeamConnection: CBPeripheral
    
    init(airbeamServices: SDCardAirBeamServices, fileWriter: SDSyncFileWriter) {
        self.airbeamServices = airbeamServices
        self.fileWriter = fileWriter
    }
    
    func syncFromAirbeam(_ airbeamConnection: CBPeripheral, completion: @escaping (Bool) -> Void) {
        airbeamServices.downloadData(from: airbeamConnection, progress: { [weak self] chunk in
            // Filesystem write
            self?.fileWriter.writeToFile(data: chunk.payload, sessionType: chunk.sessionType)
        }, completion: { [weak self] result in
            switch result {
            case .success: self?.fileWriter.finishAndSave(); completion(true)
            case .failure: self?.fileWriter.finishAndRemoveFiles()
            }
        })
    }
}
