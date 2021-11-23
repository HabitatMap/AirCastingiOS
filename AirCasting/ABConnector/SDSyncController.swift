// Created by Lunar on 17/11/2021.
//

import Foundation
import CoreBluetooth

protocol SDSyncFileWriter {
    func writeToFile(data: String, sessionType: SDCardSessionType)
}

class SDSyncController: ObservableObject {
    private let fileWriter: SDSyncFileWriter
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
        })
    }
}
