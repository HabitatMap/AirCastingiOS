import Foundation
import CoreLocation

extension Database {
    public struct Measurement: Hashable {
        public let id: MeasurementID
        public let time: Date
        public let value: Double
        public let latitude: Double?
        public let longitude: Double?
        
        public init(
            id: MeasurementID,
            time: Date,
            value: Double,
            latitude: Double?,
            longitude: Double?
        ) {
            self.id = id
            self.time = time
            self.value = value
            self.latitude = latitude
            self.longitude = longitude
        }
    }
}
