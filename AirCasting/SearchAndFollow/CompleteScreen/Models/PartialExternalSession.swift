// Created by Lunar on 04/05/2022.
//

import Foundation

struct PartialExternalSession {
    let id: Int
    let uuid: String
    let provider: String
    let name: String
    let startTime: Date
    let endTime: Date
    let longitude: Double
    let latitude: Double
    var stream: [Stream]
    
    struct Stream {
        let id: Int
        let unitName: String
        let unitSymbol: String
        let measurementShortType: String
        let measurementType: String
        let sensorName: String
        let sensorPackageName: String
        let thresholdsValues: ThresholdsValue
    }
    
    static var mock: PartialExternalSession {
        let session =  self.init(id: 1,
                                 uuid: "202411",
                                 provider: "OpenAir",
                                 name: "KAHULUI, MAUI",
                                 startTime: DateBuilder.getFakeUTCDate() - 60,
                                 endTime: DateBuilder.getFakeUTCDate(),
                                 longitude: 19.944544,
                                 latitude: 50.049683,
                                 stream: [Stream(id: 499130,
                                                 unitName: "microgram per cubic meter",
                                                 unitSymbol: "µg/m³",
                                                 measurementShortType: "PM",
                                                 measurementType: "Particulate Matter",
                                                 sensorName: "OpenAQ-PM2.5",
                                                 sensorPackageName: "OpenAQ-PM2.5",
                                                 thresholdsValues: ThresholdsValue(veryLow: 0, low: 5, medium: 8, high: 10, veryHigh: 12)
                                                )
                                         ])
        return session
    }
}
