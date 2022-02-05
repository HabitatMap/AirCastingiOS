//
//  Created by Lunar on 10/04/2021.
//

import Foundation
import os.log
import Resolver

public let Log: Logger = Resolver.resolve()

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

public protocol Logger {
    func log(_ message:  @escaping @autoclosure () -> String, type: LogLevel, file: String, function: String, line: Int)
}

public protocol LogFormatter {
    func format(_ message: String, type: LogLevel, file: String, function: String, line: Int) -> String
}

public class SimpleLogFormatter: LogFormatter {
    let symbols: [LogLevel: String]
    private let formatter = DateFormatter(format: "MM-dd-y HH:mm:sss", timezone: .utc)
    
    public init(symbols: [LogLevel: String] = [.info: "👀", .warning: "⚠️", .error: "‼️"]) {
        self.symbols = symbols
    }

    public func format(_ message: String, type: LogLevel, file: String, function: String, line: Int) -> String {
        let file = file.split(separator: "/").last.map(String.init) ?? file
        let date = "[\(formatter.string(from: DateBuilder.getRawDate()))]"
        let message = symbols[type].flatMap { $0 + " " + message } ?? message
        return "\(date) \(file): \(message)"
    }
}

public extension Logger {
    func warning(_ message: @escaping @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(message(), type: .warning, file: file, function: function, line: line)
    }

    func error(_ message: @escaping @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(message(), type: .error, file: file, function: function, line: line)
    }

    func verbose(_ message: @escaping @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(message(), type: .verbose, file: file, function: function, line: line)
    }

    func info(_ message: @escaping @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(message(), type: .info, file: file, function: function, line: line)
    }

    func debug(_ message: @escaping @autoclosure () -> String, file: String = #fileID, function: String = #function, line: Int = #line) {
        log(message(), type: .debug, file: file, function: function, line: line)
    }
}
