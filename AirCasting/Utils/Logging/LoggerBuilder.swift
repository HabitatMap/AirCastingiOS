// Created by Lunar on 05/02/2022.
//

import Foundation
import DeviceKit

/// Utility class to simplify logger creation process.
class LoggerBuilder {
    enum LoggerType {
        case file
        case debug
        case crashlytics
        case crashlyticsError
    }
    
    private init() { }
    
    static let shared = LoggerBuilder()
    
    private var partialLogger: Logger!
    private let formatter: LogFormatter = SimpleLogFormatter()
    private let headerProvider: FileLoggerHeaderProvider = {
        let loggerDateFormatter = DateFormatter(format: "MM-dd-y HH:mm:ss", timezone: .utc, locale: Locale(identifier: "en_US"))
        return AirCastingLogoFileLoggerHeaderProvider(logVersion: "1.0",
                                                      created: loggerDateFormatter.string(from: DateBuilder.getRawDate()),
                                                      device: "\(Device.current)",
                                                      os: "\(Device.current.systemName ?? "??") \(Device.current.systemVersion ?? "??")") as FileLoggerHeaderProvider
    }()
    lazy var store: DocumentsFileLoggerStore = DocumentsFileLoggerStore(logDirectory: "logs",
                                                                        logFilename: "log.txt",
                                                                        maxLogs: 30000,
                                                                        overflowThreshold: 500,
                                                                        headerProvider: headerProvider)
    
    // TODO: Refactor this so it doesn't require withType to be called
    @discardableResult
    func withType(_ type: LoggerType) -> Self {
        switch type {
        case .debug: partialLogger = createDebugLogger()
        case .file: partialLogger = createFileLogger()
        case .crashlytics: partialLogger = createCrashlyticsLogger()
        case .crashlyticsError: partialLogger = createCrashlyticsErrorLogger()
        }
        return self
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
        partialLogger
    }
    
    
    private func createDebugLogger() -> Logger {
        PrintLogger()
    }
    
    private func createFileLogger() -> Logger {
        FileLogger(formatter: formatter, store: store)
    }
    
    private func createCrashlyticsLogger() -> Logger {
        CrashlyticsLogger(formatter: formatter)
    }
    
    private func createCrashlyticsErrorLogger() -> Logger {
        CrashlyticsErrorLogger()
    }
}
