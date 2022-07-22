// Created by Lunar on 17/05/2022.
//

import Foundation

/// Error type that can be produced by `LevelSampler`
enum LevelSamplerError: Error {
    /// Whenever a sampler disconnects this error type is returned
    case disconnected
    /// Error for when sampler was unable to read a measurement
    case readError(Error)
}

/// Interface for objects capable of taking a single measurement
protocol LevelSampler {
    associatedtype Measurement
    /// Takes a single measurement of the `Measurement` type
    /// - Parameter completion: completion closure called when the measurement is taken or an error is produced
    func sample(completion: (Result<Measurement, LevelSamplerError>) -> Void)
}
