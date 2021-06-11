import Foundation

extension Database {
    public struct Measurement {
        public let id: Int
        public let sensorName: String
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
        
        #warning("Make this private as soon as we move PersistenceController into here")
        public init(
            id: Int,
            sensorName: String,
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
