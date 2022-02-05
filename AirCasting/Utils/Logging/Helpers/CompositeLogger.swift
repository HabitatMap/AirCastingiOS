import Foundation

class CompositeLogger: Logger {
    private let loggers: [Logger]
    
    init(loggers: [Logger]) {
        self.loggers = loggers
    }
    
    func log(_ message: @escaping @autoclosure () -> String, type: LogLevel, file: String = #file, function: String = #function, line: Int = #line) {
        loggers.forEach {
            $0.log(message(), type: type, file: file, function: function, line: line)
        }
    }
}
