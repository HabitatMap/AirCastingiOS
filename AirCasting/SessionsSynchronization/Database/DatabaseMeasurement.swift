import Foundation
import CoreLocation

extension Database {
    public struct Measurement {
        let time: Date
        let value: Double
        let location: CLLocationCoordinate2D?
        
        public init(
            time: Date,
            value: Double,
            location: CLLocationCoordinate2D?
        ) {
            self.time = time
            self.value = value
            self.location = location
        }
    }
}
