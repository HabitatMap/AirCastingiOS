// Created by Lunar on 21/03/2024.
//

import Foundation

protocol SDSyncFileWriter {
    func writeToFile(data: String, parser: SDMeasurementsParser, sessionType: SDCardSessionType)
    func finishAndSave() -> [(URL, SDCardSessionType)]
    func finishAndRemoveFiles()
}
