// Created by Lunar on 29/03/2022.
//

import Foundation

struct BottomCardModel {
    let id: Int
    let uuid: String
    let title: String
    let startTime: String
    let endTime: String
    let latitude: Double
    let longitude: Double
    let stream: Stream
    let thresholds: ThresholdsValue
    
    struct Stream {
        let id: Int
        let unitName: String
        let unitSymbol: String
        let sensorName: String
        let sensorPackageName: String
        let thresholdVeryLow: Int32
        let thresholdLow: Int32
        let thresholdMedium: Int32
        let thresholdHigh: Int32
        let thresholdVeryHigh: Int32
    }
}
