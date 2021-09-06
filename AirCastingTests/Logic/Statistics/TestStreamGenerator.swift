// Created by Lunar on 06/07/2021.
//

@testable import AirCasting
import Foundation
import CoreLocation

enum TestStreamGenerator {
    // Will create stream with a given number of measurements.
    // Each measurement will have:
    // - a 1970 + Index date
    // - 0.0 + Index measurement value
    // - 0.0 + Index lat/long locations
    static func createStream(numberOfMeasurements: Int, startingDate: Date = Date(timeIntervalSince1970: 0)) -> MeasurementStreamEntity {
        let stream = MeasurementStreamEntity(context: persistence.viewContext)
        for index in 0..<numberOfMeasurements {
            let entity = MeasurementEntity(context: persistence.viewContext)
            entity.id = Int64(index)
            entity.value = 0.0 + Double(index)
            entity.location = CLLocationCoordinate2D(latitude: CLLocationDegrees(index), longitude: CLLocationDegrees(index))
            entity.time = Date(timeIntervalSince1970: Double(index))
            stream.addToMeasurements(entity)
        }
        
        try! persistence.viewContext.save()
        return stream
    }
}
