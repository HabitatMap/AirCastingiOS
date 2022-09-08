// Created by Lunar on 16/08/2022.
//

import XCTest
import Resolver
@testable import AirCasting

class MicrophoneCalibratorTest: ACTestCase {
    private let microphone = MicrophoneMock()
    private let timer = TimerMock()
    private let durationDecider = MockDurationDecider()
    
    override func setUp() {
        super.setUp()
        microphone.state = .notRecording
        Resolver.test.register { self.timer as TimerScheduler }
        Resolver.test.register { self.durationDecider as CalibrationDurationDecider }
    }
    
    // MARK: Calibration tests
    
    func test_whenMicrophoneStateIsRecording_calibrationIsUnavailable() {
        microphone.state = .recording
        
        let sut = createSUT()
        XCTAssertFalse(sut.isAvailable)
    }
    
    func test_whenMicrophoneStateIsInterrupted_calibrationIsUnavailable() {
        microphone.state = .interrupted
        
        let sut = createSUT()
        XCTAssertFalse(sut.isAvailable)
    }
    
    func test_whenMicrophoneStateIsNotRecording_calibrationIsAvailable() {
        microphone.state = .notRecording
        
        let sut = createSUT()
        XCTAssertTrue(sut.isAvailable)
    }
    
    func test_whenStartingCalibration_launchesMicrophoneRecording() {
        let sut = createSUT()
        sut.startCalibration(completion: { _ in })
        
        XCTAssertEqual(microphone.callHistory, [.start])
    }
    
    func FIXMEtest_whenStartingCalibration_setsUpTheTimer() {
        let timerValue = 10.0
        let sut = createSUT(timeBetweenMeasurements: timerValue)
        sut.startCalibration(completion: { _ in })
        
        XCTAssertEqual(timer.callHistory, [.schedule(timerValue)]) // `Double` comparison. Should be OK for 10.0 tho 🤷‍♂️
    }
    
    func test_whenStartingCalibration_andMicrophoneFails_completesWithError() throws {
        microphone.throwOnStart = true
        let result = try XCTUnwrap(calibrationResult(for: []))
        do {
            _ = try result.get()
        } catch let error as MicrophoneCalibrationError {
            guard case .microphoneError = error else { XCTFail("Expected to fail with correct error!"); return }
            return
        }
        XCTFail("Expected to fail with correct error!")
    }
    
    func test_whenTimerTicks_afterCalibrationDurationIsReached_stopsTheTimer() throws {
        let sut = createSUT()
        sut.startCalibration(completion: { _ in })
        durationDecider.shouldFinish = true
        timer.fireTimer()
        let timerToken = try XCTUnwrap(timer.lastToken)
        XCTAssertEqual(timer.callHistory.last, .stop(timerToken))
    }
    
    func test_whenTimerTicks_itChecksForCalibrationFinish_usingCorrectDate() {
        let startDate = Date(timeIntervalSinceReferenceDate: 100)
        let duration = 42.0
        let sut = createSUT(dateProvider: { startDate }, calibrationDuration: duration)
        sut.startCalibration(completion: { _ in })
        timer.fireTimer()
        XCTAssertEqual(durationDecider.callHistory.count, 1)
        XCTAssertEqual(durationDecider.callHistory, [.init(startDate: startDate, desiredDuration: duration)])
    }
    
    func test_afterStopping_stopsTheMicrophone() throws {
        _ = calibrationResult()
        XCTAssertEqual(microphone.callHistory.last, .stop)
    }
    
    func test_afterStopping_whenMinimalMeasurementsCountIsNotReached_completesWitherror() throws {
        let result = try XCTUnwrap(calibrationResult(for: [1])) // Fake a single measurements was taken during calibration window
        do {
            _ = try result.get()
        } catch let error as MicrophoneCalibrationError {
            guard case .couldntGetEnoughMeasurements = error else { XCTFail("Expected to fail with correct error!"); return }
            return
        }
        XCTFail("Expected to fail with correct error!")
    }
    
    func test_afterStopping_calculatesLowestPowerPointFromMeasurements() throws {
        let lowestPower = 10.0
        let allMeasurements = lowestPower.createArrayWithHigherValuesOnly(count: 20)
        let result = try XCTUnwrap(calibrationResult(for: allMeasurements))
        XCTAssertEqual(try result.get().lowestPower, lowestPower)
    }
    
    func test_afterStopping_calculatesHighestPowerPointFromMeasurements() throws {
        let highestPower = 100.0
        let allMeasurements = highestPower.createArrayWithLowerValuesOnly(count: 20)
        let result = try XCTUnwrap(calibrationResult(for: allMeasurements))
        XCTAssertEqual(try result.get().highestPower, highestPower)
    }
    
    // MARK: Helpers
    
    private func calibrationResult(for measurements: [Double?] = [20.0]) -> Result<MicrophoneCalibrationDescription, MicrophoneCalibrationError>? {
        let sut = createSUT()
        var result: Result<MicrophoneCalibrationDescription, MicrophoneCalibrationError>?
        sut.startCalibration(completion: { result = $0 })
        for (i, measurement) in measurements.enumerated() {
            microphone.stubbedLevel = measurement
            // If it was the last measurement, finish.
            if i == measurements.count-1 { durationDecider.shouldFinish = true }
            timer.fireTimer()
        }
        return result
    }
    
    private func createSUT(dateProvider: @escaping () -> Date = DateBuilder.getRawDate,
                           minimalMeasurementsCount: UInt = 12,
                           calibrationDuration: Double = 5.0,
                           timeBetweenMeasurements: Double = 0.25) -> MicrophoneCalibrator {
        return MicrophoneCalibrator(microphone: microphone,
                                    dateProvider: dateProvider,
                                    minimalMeasurementsCount: minimalMeasurementsCount,
                                    calibrationDuration: calibrationDuration,
                                    timeBetweenMeasurements: timeBetweenMeasurements)
    }
    
    // MARK: Test doubles
    
    private class MockDurationDecider: CalibrationDurationDecider {
        var shouldFinish = false
        
        struct HistoryItem: Equatable {
            let startDate: Date
            let desiredDuration: Double
        }
        
        private(set) var callHistory: [HistoryItem] = []
        
        func shouldCalibrationFinish(calibrationStartDate: Date, desiredDuration: Double) -> Bool {
            callHistory.append(.init(startDate: calibrationStartDate, desiredDuration: desiredDuration))
            return shouldFinish
        }
    }
}
