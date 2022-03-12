import XCTest
@testable import AirCasting

class ThresholdLoggerProxyTests: ACTestCase {
    func test_onLog_logsOnlyMinimalLogLevelOrHigher() {
        let loggerSpy = LoggerSpy()
        let sut = ThresholdLoggerProxy(thresholdLevel: .warning, logger: loggerSpy)
        sut.log("test1", type: .verbose)
        sut.log("test2", type: .debug)
        sut.log("test3", type: .info)
        sut.log("test4", type: .warning)
        sut.log("test5", type: .error)
        XCTAssertEqual(loggerSpy.logged, [.init(message: "test4", level: .warning),
                                          .init(message: "test5", level: .error)])
    }
}
