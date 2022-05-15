// Created by Lunar on 15/05/2022.
//

import Foundation
import CoreLocation
import Resolver

enum SamplerState {
    case connected, disconnected
}

struct LevelSamplerDisconnectedError: Error { }

protocol LevelSampler {
    associatedtype Measurement
    func sample(completion: (Result<Measurement, Error>) -> Void)
}

protocol MeasurementSaveable {
    associatedtype Measurement
    func saveMeasurement(_: Measurement, completion: @escaping (Result<Void, Error>) -> Void)
}

final class LevelMeasurementController<SamplerType: LevelSampler, SaverType: MeasurementSaveable> where SamplerType.Measurement == SaverType.Measurement {
    private var sampler: SamplerType
    private let measurementSaver: SaverType
    private let timer: TimerScheduler
    
    private var timerToken: AnyObject?
    
    init(sampler: SamplerType, measurementSaver: SaverType, timer: TimerScheduler) {
        self.sampler = sampler
        self.measurementSaver = measurementSaver
        self.timer = timer
    }
    
    func startMeasuring(with interval: TimeInterval) {
        timerToken = timer.schedule(every: interval) { [weak self] in
            self?.sampler.sample { [weak self] newMeasurement in
                do {
                    self?.measurementSaver.saveMeasurement(try newMeasurement.get(), completion: { result in
                        switch result {
                        case .success: Log.verbose("Measurement saved")
                        case .failure(let error): Log.error("Failed to save measurement: \(error)")
                        }
                    })
                } catch _ as LevelSamplerDisconnectedError {
                    Log.verbose("Sampler disconnected")
                } catch {
                    Log.error("Sampling failed: \(error)")
                }
            }
        }
    }
    
    deinit {
        if let timerToken = timerToken {
            timer.stop(token: timerToken)
        }
    }
}
