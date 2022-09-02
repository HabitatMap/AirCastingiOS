import Foundation

/// A decorator providing scheduling `Logger` to a given `DispatchQueue`
class ScheduledLogger: Logger {
    private let queue: DispatchQueue
    private let logger: Logger
    
    init(queue: DispatchQueue, logger: Logger) {
        self.queue = queue
        self.logger = logger
    }
    
    func log(_ message: @escaping @autoclosure () -> String, type: LogLevel, file: String = #fileID, function: String = #function, line: Int = #line) {
        let msg = message()
        queue.async {
            self.logger.log(msg, type: type, file: file, function: function, line: line)
        }
    }
}
