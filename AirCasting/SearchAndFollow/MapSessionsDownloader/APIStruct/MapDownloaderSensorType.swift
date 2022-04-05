// Created by Lunar on 04/04/2022.
//

import Foundation

enum MapDownloaderSensorType: Codable {
    case AB325
    case AB225
    case OpenAQ
    case OzoneSensor
}

extension MapDownloaderSensorType {
    var name: String {
        switch self {
        case .AB325: return "airbeam3-pm2.5"
        case .AB225: return "airbeam2-pm2.5"
        case .OpenAQ: return"openaq-pm2.5"
        case .OzoneSensor: return "openaq-o3"
        }
    }
}
