// Created by Lunar on 15/05/2022.
//

import Foundation
import CoreLocation
import Resolver

final class LevelMeasurementController<Sampler: LevelSampler, Saver: MeasurementSaveable>: LevelMeasurer where Sampler.Measurement == Saver.Measurement {
    private var sampler: Sampler
    private let measurementSaver: Saver
    private let timer: TimerScheduler
    private var timerToken: AnyObject?
    
    init(sampler: Sampler, measurementSaver: Saver, sessionStopper: SessionStoppable, timer: TimerScheduler) {
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
                    Log.verbose("[DEBUG] Sampler disconnected")
                    self?.measurementSaver.handleInterruption()
                } catch {
                    Log.error("Sampling failed: \(error)")
                }
            }
        }
    }
    
    deinit {
        Log.info("[DEBUG] Deinitialized")
        if let timerToken = timerToken {
            timer.stop(token: timerToken)
        }
    }
}
