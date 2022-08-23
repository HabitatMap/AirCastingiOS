// Created by Lunar on 17/05/2022.
//

import Foundation

/// Interface for objects that are able to save a single measurement value to data store
protocol MeasurementSaveable {
    associatedtype Measurement
    /// Saves a single measurement of the `Measurement` type
    /// - Parameters:
    ///   - _: a measurement value
    ///   - completion: completion closure called when the measurement is saved or an error is produced
    func saveMeasurement(_: Measurement, completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Handle anything store-related for when measuring gets interrupted
    func handleInterruption()
}
