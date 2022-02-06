import Foundation

/// Resettable file log holder. It is expected that the logfile is emptied upon resetting.
protocol FileLoggerResettable {
    func resetFile() throws
}

/// A class responsible for the process of dosposing logger data in case the system asks us to free up disk storage.
class FileLoggerDisposer: DisposableDataHolder {
    private let resettableLogger: FileLoggerResettable
    let disposeQueue: DispatchQueue?
    
    init(resettableLogger: FileLoggerResettable, disposeQueue: DispatchQueue?) {
        self.resettableLogger = resettableLogger
        self.disposeQueue = disposeQueue
    }
    
    func dispose() throws {
        try resettableLogger.resetFile()
    }
}
