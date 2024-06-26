// Created by Lunar on 09/12/2021.
//

import Foundation

struct SDStream: Hashable {
    let sessionUUID: SessionUUID
    let deviceID: String
    let name: MeasurementStreamSensorName
    let header: SDCardCSVFileFactory.Header
}

extension String {
    var isMini: Bool {
        return self.lowercased().contains(AirBeamDeviceType.airBeamMini.rawName.lowercased())
    }
}
