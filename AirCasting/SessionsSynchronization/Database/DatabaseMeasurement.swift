import Foundation

extension Database {
    public struct Measurement {
        public let id: MeasurementID
        public let sensorName: SensorName
        public let sensorPackageName: String
        public let unitName: String
        public let measurementType: String
        public let measurementShortType: String
        public let unitSymbol: String
        public let thresholdVeryLow: Int
        public let thresholdLow: Int
        public let thresholdMedium: Int
        public let thresholdHigh: Int
        public let thresholdVeryHigh: Int
        public let isDeleted: Bool
        
        public init(
            id: MeasurementID,
            sensorName: SensorName,
            sensorPackageName: String,
            unitName: String,
            measurementType: String,
            measurementShortType: String,
            unitSymbol: String,
            thresholdVeryLow: Int,
            thresholdLow: Int,
            thresholdMedium: Int,
            thresholdHigh: Int,
            thresholdVeryHigh: Int,
            isDeleted: Bool
        ) {
            self.id = id
            self.sensorName = sensorName
            self.sensorPackageName = sensorPackageName
            self.unitName = unitName
            self.measurementType = measurementType
            self.measurementShortType = measurementShortType
            self.unitSymbol = unitSymbol
            self.thresholdVeryLow = thresholdVeryLow
            self.thresholdLow = thresholdLow
            self.thresholdMedium = thresholdMedium
            self.thresholdHigh = thresholdHigh
            self.thresholdVeryHigh = thresholdVeryHigh
            self.isDeleted = isDeleted
        }
    }
}
