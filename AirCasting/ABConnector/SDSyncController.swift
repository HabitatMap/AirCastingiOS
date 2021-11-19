// Created by Lunar on 17/11/2021.
//

import Foundation
import CoreBluetooth

class SDSyncController: ObservableObject {
    private var fileWriter: SDSyncFileWriter
    private let airbeamServices: SDCardAirBeamServices
//    private let airbeamConnection: CBPeripheral
    
    init(airbeamServices: SDCardAirBeamServices, fileWriter: SDSyncFileWriter) {
        self.airbeamServices = airbeamServices
        self.fileWriter = fileWriter
    }
    
    func syncFromAirbeam(_ airbeamConnection: CBPeripheral) {
        airbeamServices.downloadData(from: airbeamConnection, progress: { [weak self] chunk in
            // Filesystem write
            self?.fileWriter.writeToFile(data: chunk.payload, sessionType: chunk.sessionType)
        }, completion: { [weak self] result in
            switch result {
            case .success: self?.fileWriter.finishAndSave()
            case .failure: self?.fileWriter.finishAndRemoveFiles()
            }
        })
    }
}
