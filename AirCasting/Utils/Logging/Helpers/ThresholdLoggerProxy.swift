import Foundation

/// A proxy that will drop messages that have lower `LogLevel` than the provided threshold.
class ThresholdLoggerProxy: Logger {
    private let thresholdLevel: LogLevel
    private let logger: Logger
    
    init(thresholdLevel: LogLevel, logger: Logger) {
        self.thresholdLevel = thresholdLevel
        self.logger = logger
    }
    
    func log(_ message: @escaping @autoclosure () -> String, type: LogLevel, file: String = #file, function: String = #function, line: Int = #line) {
        guard thresholdLevel.rawValue <= type.rawValue else {
            return
        }
        logger.log(message(), type: type, file: file, function: function, line: line)
    }
}
