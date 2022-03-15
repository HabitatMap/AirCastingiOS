import XCTest
@testable import AirCasting

class ScheduledLoggerTests: ACTestCase {
    func test_onLog_schedulesToAGivenQueue() {
        let loggerSpy = LoggerQueueSpy()
        let sut = ScheduledLogger(queue: .global(), logger: loggerSpy)
        let message = "test"
        let level = LogLevel.debug
        sut.log("test", type: level)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1)) // This is the only way to wait for background queue here.
        XCTAssertEqual(loggerSpy.history, [.init(wasMainThread: false, message: message, level: level)])
    }
    
    func test_onLog_doesntAccessReleasedData() {
        let queue = DispatchQueue.global()
        queue.suspend()
        let logger = LoggerQueueSpy()
        let sut = ScheduledLogger(queue: queue, logger: logger)
        _ = UsesInternalPropertyToLogOnDeinit(logString: "Hello", logger: sut)
        queue.resume()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1)) // This is the only way to wait for background queue here.
        // If we reach the end of this test without an EXC_BAD_ACCESS it works!
        XCTAssertEqual(logger.history, [.init(wasMainThread: false, message: "Hello", level: .info)])
    }
}

class UsesInternalPropertyToLogOnDeinit {
    class Dummy: CustomDebugStringConvertible {
        let debugDescription: String
        init(_ description: String) {
            self.debugDescription = description
        }
    }
    
    let dummy: Dummy
    let logger: Logger
    
    init(logString: String, logger: Logger) {
        self.dummy = .init(logString)
        self.logger = logger
    }
    
    deinit {
        logger.info("\(dummy)")
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
