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
    // maxLogs sized to retain a full 9h+ session: real logs average ~3.6 lines/s
    // (8h-tail sample: 30468 lines / 8345 s), so 300k covers ~20h typical and
    // ~10h at the densest sustained rate — the whole trace survives a mid-session
    // crash (the file is append-only across relaunch; see DocumentsFileLoggerStore).
    // overflowThreshold raised so trimming this larger file happens rarely (once
    // per 25k lines over cap) instead of every 500 lines.
    lazy var store: DocumentsFileLoggerStore = DocumentsFileLoggerStore(logDirectory: "logs",
                                                                        logFilename: "log.txt",
                                                                        maxLogs: 300000,
                                                                        overflowThreshold: 25000,
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
