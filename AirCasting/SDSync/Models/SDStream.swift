// Created by Lunar on 09/12/2021.
//

import Foundation

struct SDStream: Hashable {
    let sessionUUID: SessionUUID
    let name: MeasurementStreamSensorName
    let header: SDCardCSVFileFactory.Header
}

