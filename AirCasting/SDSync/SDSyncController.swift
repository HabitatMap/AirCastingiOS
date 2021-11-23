// Created by Lunar on 17/11/2021.
//

import Foundation
import CoreBluetooth

protocol SDSyncFileWriter {
    func writeToFile(data: String, for: SDCardSessionType)
}

class SDSyncController {
    private let fileWriter: SDSyncFileWriter
    private let airbeamServices: SDCardAirBeamServices
    private let airbeamConnection: CBPeripheral
    
    init(airbeamServices: SDCardAirBeamServices, airbeamConnection: CBPeripheral, fileWriter: SDSyncFileWriter) {
        self.airbeamServices = airbeamServices
        self.airbeamConnection = airbeamConnection
        self.fileWriter = fileWriter
    }
    
    func syncFromAirbeam() {
        airbeamServices.downloadData(from: airbeamConnection, progress: { [weak self] chunk in
            // Filesystem write
            self?.fileWriter.writeToFile(data: chunk.payload, for: chunk.sessionType)
        })
    }
}
