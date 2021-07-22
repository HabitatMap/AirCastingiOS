// Created by Lunar on 16/06/2021.
//

import Combine

extension Publisher {
    /// Logs any error ending the upstream using provided logging function *and* tears downstream as completed.
    /// - Parameters:
    ///   - message: A message that will prefix the `error.localizedDescription` printout.
    ///   - logFunc: Optional custom logging function.
    /// - Returns: A publisher that matches the upstream `Output` and has a `Failure` set to `Never`.
    func logErrorAndComplete(message: String = "",
                             file: String = #file,
                             function: String = #function,
                             line: Int = #line,
                             logFunc: @escaping Publishers.Logging.LogFunc = { Log.error($0, file: $1, function: $2, line: $3) }) -> Publishers.LogErrorAndComplete<Self> {
        .init(upstream: self, logMessage: message, file: file, function: function, line: line, logFunc: logFunc)
    }
}

extension Publishers {
    struct LogErrorAndComplete<Upstream: Publisher>: Publisher {
        typealias Output = Upstream.Output
        typealias Failure = Never
        
        private let upstream: Upstream
        private let logMessage: String
        private let file: String
        private let function: String
        private let line: Int
        private let logFunc: Publishers.Logging.LogFunc
        
        init(upstream: Upstream,
             logMessage: String,
             file: String,
             function: String,
             line: Int,
             logFunc: @escaping Publishers.Logging.LogFunc) {
            self.upstream = upstream
            self.logMessage = logMessage
            self.file = file
            self.function = function
            self.line = line
            self.logFunc = logFunc
        }
        
        func receive<S: Subscriber>(subscriber: S) where S.Input == Upstream.Output, S.Failure == Never {
            self.upstream
                .catch { error -> Empty<S.Input, Never> in
                    logFunc("\(logMessage): \(error.localizedDescription)", file, function, line)
                    return Empty()
                }
                .subscribe(subscriber)
        }
    }
}
