import Foundation

protocol FileLoggerResettable {
    func resetFile() throws
}

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
