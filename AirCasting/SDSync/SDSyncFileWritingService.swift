// Created by Lunar on 18/11/2021.
//

import Foundation

struct SDSyncFileWritingService: SDSyncFileWriter {
    func finishAndSave() {
        //
    }
    
    func finishAndRemoveFiles() {
        //
    }
    
    func writeToFile(data: String, sessionType: SDCardSessionType) {
        let dataEntries = data.components(separatedBy: "\r\n").filter { !$0.trimmingCharacters(in: ["\n"]).isEmpty }
        Log.info("## Data entries: \(dataEntries)")
        // write to file
    }
}
