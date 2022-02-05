import XCTest
@testable import AirCasting

class ScheduledLoggerTests: XCTestCase {
    func test_onLog_schedulesToAGivenQueue() {
        let loggerSpy = LoggerQueueSpy()
        let sut = ScheduledLogger(queue: .global(), logger: loggerSpy)
        let message = "test"
        let level = LogLevel.debug
        sut.log("test", type: level)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1)) // This is the only way to wait for background queue here.
        XCTAssertEqual(loggerSpy.history, [.init(wasMainThread: false, message: message, level: level)])
    }
}

class LoggerQueueSpy: Logger {
    struct CallHistoryItem: Equatable {
        let wasMainThread: Bool
        let message: String
        let level: LogLevel
    }
    
    private(set) var history: [CallHistoryItem] = []
    
    func log(_ message: @autoclosure @escaping () -> String, type: LogLevel, file: String, function: String, line: Int) {
        history.append(.init(wasMainThread: Thread.isMainThread, message: message(), level: type))
    }
}
