import Foundation

/// A composite providing for putting multiple `Logger` objects together.
class CompositeLogger: Logger {
    private var loggers: [Logger] = []
    
    func add(_ logger: Logger) {
        self.loggers.append(logger)
    }
    
    func log(_ message: @escaping @autoclosure () -> String, type: LogLevel, file: String = #file, function: String = #function, line: Int = #line) {
        loggers.forEach {
            $0.log(message(), type: type, file: file, function: function, line: line)
        }
    }
}
