// Created by Lunar on 05/02/2022.
//

import Foundation

protocol FileLoggerStore {
    func openOrCreateLogFile() throws -> FileLoggerFileHandle
}

protocol FileLoggerFileHandle {
    func appendFile(with: String) throws
}

class FileLogger: Logger {
    private let store: FileLoggerStore
    private let fileHandle: FileLoggerFileHandle
    private let formatter: LogFormatter
    
    init(store: FileLoggerStore, formatter: LogFormatter) throws {
        self.store = store
        self.fileHandle = try store.openOrCreateLogFile()
        self.formatter = formatter
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
