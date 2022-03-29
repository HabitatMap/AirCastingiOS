import Foundation
import Resolver

/// Resettable file log holder. It is expected that the logfile is emptied upon resetting.
protocol FileLoggerResettable {
    func resetFile() throws
}

/// A class responsible for the process of dosposing logger data in case the system asks us to free up disk storage.
class FileLoggerDisposer: DisposableDataHolder {
    @Injected private var resettableLogger: FileLoggerResettable
    let disposeQueue: DispatchQueue?
    
    init(disposeQueue: DispatchQueue?) {
        self.disposeQueue = disposeQueue
    }
    
    func dispose() throws {
        try resettableLogger.resetFile()
    }
}
