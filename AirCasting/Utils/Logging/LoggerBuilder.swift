// Created by Lunar on 05/02/2022.
//

import Foundation
import Resolver

class LoggerBuilder {
    enum LoggerType {
        case file
        case debug
    }
    
    private var partialLogger: Logger
    
    init(type: LoggerType) {
        switch type {
        case .debug: partialLogger = Self.createDebugLogger()
        case .file: partialLogger = Self.createFileLogger()
        }
    }
    
    @discardableResult
    func addMinimalLevel(_ minLevel: LogLevel) -> Self {
        partialLogger = ThresholdLoggerProxy(thresholdLevel: minLevel, logger: partialLogger)
        return self
    }
    
    @discardableResult
    func dispatchOn(_ queue: DispatchQueue) -> Self {
        partialLogger = ScheduledLogger(queue: queue, logger: partialLogger)
        return self
    }
    
    func build() -> Logger {
        return partialLogger
    }
    
    
    private static func createDebugLogger() -> Logger {
        PrintLogger(formatter: Resolver.resolve())
    }
    
    private static func createFileLogger() -> Logger {
        do {
            return try FileLogger(store: Resolver.resolve(),
                                  formatter: Resolver.resolve())
        } catch {
            return NullLoger()
        }
    }
    
    private struct NullLoger: Logger {
        func log(_ message: @autoclosure @escaping () -> String, type: LogLevel, file: String, function: String, line: Int) { }
    }
}
