import Foundation
import XCTest
@testable import AirCasting

class CompositeLoggerTests: XCTestCase {
    func test_onLog_callsEachSubLogger() {
        let spy1 = LoggerSpy()
        let spy2 = LoggerSpy()
        let spy3 = LoggerSpy()
        let sut = CompositeLogger(loggers: [spy1, spy2, spy3])
        
        let message = "test"
        let level = LogLevel.debug
        sut.log(message, type: level)
        
        XCTAssertEqual(spy1.logged, [.init(message: message, level: level)])
        XCTAssertEqual(spy2.logged, [.init(message: message, level: level)])
        XCTAssertEqual(spy3.logged, [.init(message: message, level: level)])
    }
}
