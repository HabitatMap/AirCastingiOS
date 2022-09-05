// Created by Lunar on 16/08/2022.
//

import Foundation
@testable import AirCasting

class TimerMock: TimerScheduler {
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
    
    private var closure: (() -> Void)?
    func fireTimer() {
        assert(closure != nil, "Firing timer before client schedules it is unsupported")
        closure?()
    }
    
    func schedule(every timeInterval: TimeInterval, closure: @escaping () -> Void) -> AnyObject {
        self.closure = closure
        callHistory.append(.schedule(timeInterval))
        lastToken = Token()
        return lastToken!
    }
    
    func stop(token: AnyObject) {
        callHistory.append(.stop(token))
    }
}

class MicrophoneMock: Microphone {
    enum CallHistoryItem: Equatable {
        case getLevel
        case start
        case stop
    }
    
    var callHistory: [CallHistoryItem] = []
    var stubbedLevel: Double? = nil
    
    var throwOnStart = false
    struct MockError: Error {}
    
    var state: MicrophoneState = .notRecording
    
    func getCurrentDecibelLevel() -> Double? {
        callHistory.append(.getLevel)
        return stubbedLevel
    }
    
    func startRecording() throws {
        callHistory.append(.start)
        if throwOnStart {
            throw MockError()
        }
    }
    
    func stopRecording() throws {
        callHistory.append(.stop)
    }
}
