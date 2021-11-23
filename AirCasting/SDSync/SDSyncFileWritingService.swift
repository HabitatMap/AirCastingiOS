// Created by Lunar on 18/11/2021.
//

import Foundation

struct SDSyncFileWritingService: SDSyncFileWriter {
    func writeToFile(data: String, sessionType: SDCardSessionType) {
        Log.info("## Writing to file: \(data), session type: \(sessionType)")
        // write to file
    }
}
