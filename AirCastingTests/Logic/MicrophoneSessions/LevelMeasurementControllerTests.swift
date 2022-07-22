import Foundation
import XCTest
@testable import AirCasting

class LevelMeasurementControllerTests: XCTestCase {
    
    func test_whenMeasuring_schedulesATimer() {
        let timerInterval: TimeInterval = 10
        let timerSpy = TimerSpy()
        let sut = LevelMeasurementController(sampler: DummySampler(),
                                             measurementSaver: DummySaver(),
                                             timer: timerSpy)
        sut.startMeasuring(with: timerInterval)
        
        XCTAssertEqual(timerSpy.callHistory, [.schedule(timerInterval)])
    }
    
    func test_whenTimerFires_samplesNewMeasurement() {
        let timerStub = TimerStub()
        let samplerSpy = SamplerSpy()
        let sut = LevelMeasurementController(sampler: samplerSpy,
                                             measurementSaver: DummySaver(),
                                             timer: timerStub)
        sut.startMeasuring(with: 10)
        XCTAssertEqual(samplerSpy.sampledTimes, 0)
        timerStub.fireTimer()
        XCTAssertEqual(samplerSpy.sampledTimes, 1)
    }
    
    func test_whenNewMeasurementComes_savesIt() {
        let timerStub = TimerStub()
        let measurementValue = 9.0
        let result: Result<Double, LevelSamplerError> = .success(measurementValue)
        let samplerStub = SamplerStub(stubbedValue: result)
        let saverSpy = SaverSpy()
        let sut = LevelMeasurementController(sampler: samplerStub,
                                             measurementSaver: saverSpy,
                                             timer: timerStub)
        sut.startMeasuring(with: 5)
        timerStub.fireTimer()
        XCTAssertEqual(saverSpy.callHistory, [.save(value: measurementValue)])
    }
    
    func test_whenSamplerDisconnects_callsHandleInterruptionOnSaver() {
        let timerStub = TimerStub()
        let result: Result<Double, LevelSamplerError> = .failure(LevelSamplerError.disconnected)
        let samplerStub = SamplerStub(stubbedValue: result)
        let saverSpy = SaverSpy()
        let sut = LevelMeasurementController(sampler: samplerStub,
                                             measurementSaver: saverSpy,
                                             timer: timerStub)
        sut.startMeasuring(with: 5)
        timerStub.fireTimer()
        XCTAssertEqual(saverSpy.callHistory, [.interrupted])
    }
    
    func test_onDeinit_stopsTimer() throws {
        let timerSpy = TimerSpy()
        var sut: LevelMeasurementController? = LevelMeasurementController(sampler: DummySampler(),
                                                                          measurementSaver: DummySaver(),
                                                                          timer: timerSpy)
        sut!.startMeasuring(with: 1)
        sut = nil
        let token = try XCTUnwrap(timerSpy.lastToken)
        XCTAssertEqual(timerSpy.callHistory, [.schedule(1), .stop(token)])
    }
    
    // MARK: - Test Doubles
    
    struct DummySampler: LevelSampler {
        func sample(completion: (Result<Double, LevelSamplerError>) -> Void) { }
    }
    
    struct DummySaver: MeasurementSaveable {
        func saveMeasurement(_: Double, completion: @escaping (Result<Void, Error>) -> Void) { }
        func handleInterruption() { }
    }
    
    class TimerSpy: TimerScheduler {
        enum CallHistoryItem: Equatable {
            case schedule(TimeInterval)
            case stop(AnyObject)
            
            static func == (lhs: CallHistoryItem, rhs: CallHistoryItem) -> Bool {
                switch (lhs, rhs) {
                case (.schedule(let lTime), .schedule(let rTime)): return lTime == rTime
                case (.stop(let lToken), .stop(let rToken)): return lToken === rToken
                default: return false
                }
            }
        }
        
        private(set) var callHistory: [CallHistoryItem] = []
        private(set) var lastToken: Token?
        
        class Token {}
        
        func schedule(every timeInterval: TimeInterval, closure: @escaping () -> Void) -> AnyObject {
            callHistory.append(.schedule(timeInterval))
            lastToken = Token()
            return lastToken!
        }
        
        func stop(token: AnyObject) {
            callHistory.append(.stop(token))
        }
    }
    
    class SamplerSpy: LevelSampler {
        var sampledTimes = 0
        
        func sample(completion: (Result<Double, LevelSamplerError>) -> Void) {
            sampledTimes += 1
        }
    }
    
    class TimerStub: TimerScheduler {
        private var closure: (() -> Void)?
        class Token {}
        
        func fireTimer() {
            assert(closure != nil, "Firing timer before client schedules it is unsupported")
            closure?()
        }
        
        func schedule(every: TimeInterval, closure: @escaping () -> Void) -> AnyObject {
            self.closure = closure
            return Token()
        }
        
        func stop(token: AnyObject) { }
    }
    
    class SamplerStub: LevelSampler {
        private let stubbedValue: Result<Double, LevelSamplerError>
        
        init(stubbedValue: Result<Double, LevelSamplerError>) {
            self.stubbedValue = stubbedValue
        }
        
        func sample(completion: (Result<Double, LevelSamplerError>) -> Void) {
            completion(stubbedValue)
        }
    }
    
    class SaverSpy: MeasurementSaveable {
        enum CallHistoryItem: Equatable {
            case save(value: Double)
            case interrupted
        }
        
        var callHistory: [CallHistoryItem] = []
        
        func saveMeasurement(_ measurement: Double, completion: @escaping (Result<Void, Error>) -> Void) {
            callHistory.append(.save(value: measurement))
        }
        
        func handleInterruption() {
            callHistory.append(.interrupted)
        }
    }
}
