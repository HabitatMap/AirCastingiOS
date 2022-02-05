import Foundation

class ScheduledLogger: Logger {
    private let queue: DispatchQueue
    private let logger: Logger
    
    init(queue: DispatchQueue, logger: Logger) {
        self.queue = queue
        self.logger = logger
    }
    
    func log(_ message: @escaping @autoclosure () -> String, type: LogLevel, file: String = #file, function: String = #function, line: Int = #line) {
        queue.async {
            self.logger.log(message(), type: type, file: file, function: function, line: line)
        }
    }
}
