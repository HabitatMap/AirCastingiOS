// Created by Lunar on 07/05/2021.
//

import Foundation

extension Database {
    public struct MeasurementStream: Hashable {
        public let id: MeasurementStreamID?
        public let sensorName: SensorName?
        public let sensorPackageName: String?
        public let measurementType: String?
        public let measurementShortType: String?
        public let unitName: String?
        public let unitSymbol: String?
        public let thresholdVeryHigh: Int
        public let thresholdHigh: Int
        public let thresholdMedium: Int
        public let thresholdLow: Int
        public let thresholdVeryLow: Int
        public let measurements: [Measurement]
        public let deleted: Bool
        
        public init(id: MeasurementStreamID?,
                    sensorName: SensorName?,
                    sensorPackageName: String?,
                    measurementType: String?,
                    measurementShortType: String?,
                    unitName: String?,
                    unitSymbol: String?,
                    thresholdVeryHigh: Int,
                    thresholdHigh: Int,
                    thresholdMedium: Int,
                    thresholdLow: Int,
                    thresholdVeryLow: Int,
                    measurements: [Measurement],
                    deleted: Bool) {
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
            self.measurements = measurements
            self.deleted = deleted
        }
    }
}
