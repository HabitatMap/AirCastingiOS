// Created by Lunar on 16/08/2022.
//

import Foundation
import Resolver

/// A struct representing an outcome of a microphone calibration session
struct MicrophoneCalibrationDescription: Equatable {
    /// A lowest power output recorded while calibrating
    let lowestPower: Double
    /// A highest power output recorded while calibrating
    let highestPower: Double
}

enum MicrophoneCalibrationError: Error {
    /// Thrown when the system could not gather sufficient amount of data for calibration
    case couldntGetEnoughMeasurements
    /// Thrown when the underlying device returns an error
    case microphoneError(Error)
}

/// Interface used to calibrate the microphone dB level
protocol MicrophoneCalibration {
    /// Tells if calibration can be started.
    /// Important: you need to check it before starting a calibration. If `startCalibration` is called on for an unavailable state the behavior is undefined
    /// - Returns: `Bool` value indicating wheter the calibration can be performed at the moment.
    var isAvailable: Bool { get }
    /// Starts a microphone calibration session
    /// - Parameter completion: closure called when the calibation finishes
    func startCalibration(completion: @escaping (Result<MicrophoneCalibrationDescription, MicrophoneCalibrationError>) -> ())
}

class MicrophoneCalibrator: MicrophoneCalibration {
    private let minimalMeasurementsCount: UInt
    private let calibrationDuration: Double
    private let timeBetweenMeasurements: Double
    
    private let microphone: Microphone
    private let dateProvider: () -> Date
    @Injected private var timerScheduler: TimerScheduler
    @Injected private var durationDecider: CalibrationDurationDecider
    
    var isAvailable: Bool { microphone.state == .notRecording }
    
    init(microphone: Microphone,
         dateProvider: @escaping () -> Date = DateBuilder.getRawDate,
         minimalMeasurementsCount: UInt = 12,
         calibrationDuration: Double = 5.0,
         timeBetweenMeasurements: Double = 0.25) {
        // Check for impossible minimal measurements count
        assert(Double(minimalMeasurementsCount) < Double(calibrationDuration / timeBetweenMeasurements))
        assert(minimalMeasurementsCount > 0)
        self.microphone = microphone
        self.dateProvider = dateProvider
        self.minimalMeasurementsCount = minimalMeasurementsCount
        self.calibrationDuration = calibrationDuration
        self.timeBetweenMeasurements = timeBetweenMeasurements
    }
    
    func startCalibration(completion: @escaping (Result<MicrophoneCalibrationDescription, MicrophoneCalibrationError>) -> ()) {
        do {
            try microphone.startRecording()
        } catch {
            completion(.failure(.microphoneError(error)))
            return
        }
        var allMeasurements: [Double?] = []
        let measurementStartDate = dateProvider()
        var token: AnyObject!
        token = timerScheduler.schedule(every: timeBetweenMeasurements) { [weak self, calibrationDuration, minimalMeasurementsCount] in
            guard let self = self else { return }
            allMeasurements.append(self.microphone.getCurrentDecibelLevel())
            guard self.durationDecider.shouldCalibrationFinish(calibrationStartDate: measurementStartDate,
                                                               desiredDuration: calibrationDuration) else { return }
            try? self.microphone.stopRecording()
            self.timerScheduler.stop(token: token)
            let values = allMeasurements.compactMap { $0 }
            guard values.count >= minimalMeasurementsCount else {
                completion(.failure(.couldntGetEnoughMeasurements))
                return
            }
            let sortedValues = values.sorted(by: <)
            completion(.success(.init(lowestPower: sortedValues.first!,
                                      highestPower: sortedValues.last!)))
        }
    }
}
