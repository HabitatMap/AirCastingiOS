// Created by Lunar on 07/05/2021.
//

import Foundation

struct MeasurementStream: Hashable {
    let id: MeasurementStreamID?
    let sensorName: String?
    let sensorPackageName: String?
    let measurementType: String?
    let measurementShortType: String?
    let unitName: String?
    let unitSymbol: String?
    let thresholdVeryHigh: Int32
    let thresholdHigh: Int32
    let thresholdMedium: Int32
    let thresholdLow: Int32
    let thresholdVeryLow: Int32
}
