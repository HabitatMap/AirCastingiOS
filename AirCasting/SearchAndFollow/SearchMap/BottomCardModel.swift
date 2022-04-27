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
        let thresholdVeryLow: Int
        let thresholdLow: Int
        let thresholdMedium: Int
        let thresholdHigh: Int
        let thresholdVeryHigh: Int
    }
}
