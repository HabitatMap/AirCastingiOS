// Created by Lunar on 05/02/2022.
//

import Foundation
import Resolver

/// Use d by the `FileLogger` for opening log files
protocol FileLoggerStore {
    func openOrCreateLogFile() -> FileLoggerFileHandle
}

/// Returned by the `FileLoggerStore`. Used for appending previously opened file
/// - Note:
/// The system is designed so that file closes after releasing this handle from the memory.
protocol FileLoggerFileHandle {
    /// Appends the file with a given string
    func appendFile(with: String) throws
}

/// A logger that outputs logs into a file
class FileLogger: Logger {
    private let fileHandle: FileLoggerFileHandle
    @Injected private var formatter: LogFormatter
    
    init() {
        self.fileHandle = Resolver.resolve(FileLoggerStore.self).openOrCreateLogFile()
    }
    
    func log(_ message: @escaping @autoclosure () -> String, type: LogLevel, file: String = #file, function: String = #function, line: Int = #line) {
        let formattedMessage = formatter.format(message(), type: type, file: file, function: function, line: line)
        do {
            try fileHandle.appendFile(with: formattedMessage)
        } catch {
            assertionFailure("File logger failed to log message: \(formattedMessage) with error: \(error.localizedDescription)")
        }
    }
}
