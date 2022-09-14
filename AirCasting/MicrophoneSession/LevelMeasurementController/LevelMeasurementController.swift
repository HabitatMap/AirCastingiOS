// Created by Lunar on 15/05/2022.
//

import Foundation
import CoreLocation

final class LevelMeasurementController<Sampler: LevelSampler, Saver: MeasurementSaveable>: LevelMeasurer where Sampler.Measurement == Saver.Measurement {
    private var sampler: Sampler
    private let measurementSaver: Saver
    private let timer: TimerScheduler
    private var timerToken: AnyObject?
    
    init(sampler: Sampler, measurementSaver: Saver, timer: TimerScheduler) {
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
                } catch let error as LevelSamplerError {
                    switch error {
                    case .disconnected: self?.measurementSaver.handleInterruption()
                    case .readError(let readError): Log.error("Sampling failed with read error: \(readError.localizedDescription)")
                    }
                } catch {
                    Log.error("Sampling failed with unexpected error: \(error)")
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
