// Created by Lunar on 16/06/2021.
//

import Combine

extension Publisher {
    /// Logs any error ending the upstream using provided logging function *and* tears downstream as completed.
    /// - Parameters:
    ///   - message: A message that will prefix the `error.localizedDescription` printout.
    ///   - logFunc: Optional custom logging function.
    /// - Returns: A publisher that matches the upstream `Output` and has a `Failure` set to `Never`.
    func logErrorAndComplete(message: String = "", logFunc: @escaping (String) -> Void = { Log.info($0) }) -> Publishers.LogErrorAndComplete<Self> {
        .init(upstream: self, logMessage: message, logFunc: logFunc)
    }
}

extension Publishers {
    struct LogErrorAndComplete<Upstream: Publisher>: Publisher {
        typealias Output = Upstream.Output
        typealias Failure = Never
        
        private let upstream: Upstream
        private let logMessage: String
        private let logFunc: (String) -> Void
        
        init(upstream: Upstream, logMessage: String, logFunc: @escaping (String) -> Void) {
            self.upstream = upstream
            self.logMessage = logMessage
            self.logFunc = logFunc
        }
        
        func receive<S: Subscriber>(subscriber: S) where S.Input == Upstream.Output, S.Failure == Never {
            self.upstream
                .catch { error -> Empty<S.Input, Never> in
                    logFunc("\(logMessage): \(error.localizedDescription)")
                    return Empty()
                }
                .subscribe(subscriber)
        }
    }
}
