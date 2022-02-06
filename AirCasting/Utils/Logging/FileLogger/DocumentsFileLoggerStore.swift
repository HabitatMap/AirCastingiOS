import Foundation
import Resolver

class DocumentsFileLoggerStore: FileLoggerStore, FileLoggerResettable, LogfileProvider {
    private weak var currentHandle: LogHandle?
    private let logDirectory: String
    private let logFilename: String
    private let maxLogs: UInt
    private let overflowThreshold: UInt
    @Injected private var headerProvider: FileLoggerHeaderProvider
    
    /// For `maxLogs` and `overflowThreshold`docs please refer to the `LogHandle`
    init(logDirectory: String, logFilename: String, maxLogs: UInt, overflowThreshold: UInt) {
        self.logDirectory = logDirectory
        self.logFilename = logFilename
        self.maxLogs = maxLogs
        self.overflowThreshold = overflowThreshold
    }
    
    func openOrCreateLogFile() -> FileLoggerFileHandle {
        do {
            return try _openOrCreateLogFile()
        } catch {
            return EmptyFileLoggerFileHandle()
        }
    }
    
    func resetFile() throws {
        guard let currentHandle = self.currentHandle else { return }
        try currentHandle.saveBufferContents()
        try FileManager.default.removeItem(at: currentHandle.filePath)
        try createNewLogFile()
    }
    
    func logFileURLForSharing() -> URL? {
        guard let currentHandle = currentHandle else { return nil}
        do {
            try currentHandle.saveBufferContents()
        } catch {
            return nil
        }
        return getLogFilePath()
    }
    
    private func _openOrCreateLogFile() throws -> LogHandle {
        guard currentHandle == nil else { throw DocumentsFileLoggerStoreError.logFileAlreadyOpened }
        let fileURL = getLogFilePath()
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try createNewLogFile()
        }
        return try generateHandle(for: fileURL)
    }
    
    func getLogFilePath() -> URL {
        getLogFileDirectory().appendingPathComponent(logFilename)
    }
    
    private func getLogFileDirectory() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logsDirURL = documentsURL.appendingPathComponent(logDirectory, isDirectory: true)
        return logsDirURL
    }
    
    private func createNewLogFile() throws {
        let directoryURL = getLogFileDirectory()
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        let fileURL = getLogFilePath()
        guard FileManager.default.createFile(atPath: fileURL.path,
                                             contents: headerProvider.headerText.data(using: .utf8)!,
                                             attributes: nil) else {
            assertionFailure("Couldn't create log file at \(fileURL)")
            throw DocumentsFileLoggerStoreError.couldntCreateLogFile
        }
    }
    
    private func generateHandle(for fileURL: URL) throws -> LogHandle {
        let handle = try LogHandle(filePath: fileURL,
                                   headerLineCount: UInt(headerProvider.headerText.isEmpty ? 0 : headerProvider.headerText.components(separatedBy: .newlines).count),
                                   maxLogs: maxLogs,
                                   overflowThreshold: overflowThreshold)
        currentHandle = handle
        return handle
    }
}

private enum DocumentsFileLoggerStoreError: String, Error, LocalizedError {
    case couldntCreateLogFile
    case logFileAlreadyOpened
    var errorDescription: String? { self.rawValue }
}

extension DocumentsFileLoggerStore {
    class EmptyFileLoggerFileHandle: FileLoggerFileHandle {
        func appendFile(with: String) throws { }
    }
}
