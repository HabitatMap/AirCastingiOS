//
//  Created by Lunar on 10/04/2021.
//

import Foundation
import os.log

public let Log: Logger = PrintLogger(level: .verbose)

public enum LogLevel: UInt, CustomStringConvertible {
    case verbose, debug, info, warning, error

    public var description: String {
        switch self {
        case .verbose: return "Verbose"
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

public protocol LogFormatter {
    func format(_ message: String, type: LogLevel, file: String, function: String, line: Int) -> String
}

public class SimpleLogFormatter: LogFormatter {
    let symbols: [LogLevel: String]
    public init(symbols: [LogLevel: String] = [.warning: "⚠️", .error: "‼️"]) {
        self.symbols = symbols
    }

    public func format(_ message: String, type: LogLevel, file: String, function: String, line: Int) -> String {
        let file = file.split(separator: "/").last.map(String.init) ?? file
        let message = "\(file): \(message)"

        #if DEBUG
        return (symbols[type].flatMap { $0 + message } ?? message) + "\n"
        #else
        return symbols[type].flatMap { $0 + message } ?? message
        #endif
    }
}

public final class PrintLogger: Logger {
    let formatter: LogFormatter
    public var level: LogLevel

    public init(level: LogLevel = .verbose, formatter: LogFormatter = SimpleLogFormatter()) {
        self.formatter = formatter
        self.level = level
    }

    public func log(_ message: @autoclosure () -> String, type: LogLevel, file: String = #fileID, function: String = #function, line: Int = #line) {
        guard self.level.rawValue >= level.rawValue else {
            return
        }
        Log.info(formatter.format(message(), type: type, file: file, function: function, line: line))
    }
}

public protocol Logger {
    func log(_ message: @autoclosure () -> String, type: LogLevel, file: String, function: String, line: Int)
}

public extension Logger {
    func warning(_ message: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(message(), type: .warning, file: file, function: function, line: line)
    }

    func error(_ message: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(message(), type: .error, file: file, function: function, line: line)
    }

    func verbose(_ message: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(message(), type: .verbose, file: file, function: function, line: line)
    }

    func info(_ message: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(message(), type: .info, file: file, function: function, line: line)
    }

    func debug(_ message: @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(message(), type: .debug, file: file, function: function, line: line)
    }
}
