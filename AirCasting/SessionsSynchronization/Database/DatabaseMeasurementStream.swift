// Created by Lunar on 07/05/2021.
//

import Foundation

extension Database {
    public struct MeasurementStream: Hashable {
        public let id: MeasurementStreamID?
        public let sensorName: String?
        public let sensorPackageName: String?
        public let measurementType: String?
        public let measurementShortType: String?
        public let unitName: String?
        public let unitSymbol: String?
        public let thresholdVeryHigh: Int32
        public let thresholdHigh: Int32
        public let thresholdMedium: Int32
        public let thresholdLow: Int32
        public let thresholdVeryLow: Int32
        
        public init(id: MeasurementStreamID?,
                    sensorName: String?,
                    sensorPackageName: String?,
                    measurementType: String?,
                    measurementShortType: String?,
                    unitName: String?,
                    unitSymbol: String?,
                    thresholdVeryHigh: Int32,
                    thresholdHigh: Int32,
                    thresholdMedium: Int32,
                    thresholdLow: Int32,
                    thresholdVeryLow: Int32) {
            self.id = id
            self.sensorName = sensorName
            self.sensorPackageName = sensorPackageName
            self.measurementType = measurementType
            self.measurementShortType = measurementShortType
            self.unitName = unitName
            self.unitSymbol = unitSymbol
            self.thresholdVeryHigh = thresholdVeryHigh
            self.thresholdHigh = thresholdHigh
            self.thresholdMedium = thresholdMedium
            self.thresholdLow = thresholdLow
            self.thresholdVeryLow = thresholdVeryLow
        }
    }
}
