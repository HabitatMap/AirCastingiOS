// Created by Lunar on 17/05/2022.
//

import Foundation

/// Whenever a sampler disconnects this error type is returned
struct LevelSamplerDisconnectedError: Error { }

/// Interface for objects capable of taking a single measurement
protocol LevelSampler {
    associatedtype Measurement
    /// Takes a single measurement of the `Measurement` type
    /// - Parameter completion: completion closure called when the measurement is taken or an error is produced
    func sample(completion: (Result<Measurement, Error>) -> Void)
}
