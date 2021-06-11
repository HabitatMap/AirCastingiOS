// Created by Lunar on 16/06/2021.
//

import Combine

extension Publisher {
    /// Logs any error ending the upstream using provided logging function.
    /// - Parameters:
    ///   - message: A message that will prefix the `error.localizedDescription` printout.
    ///   - logFunc: Optional custom logging function.
    /// - Returns: A publisher that matches upstream `Output` and `Failure` types.
    func logError(message: String = "", logFunc: @escaping (String) -> Void = { Log.error($0) }) -> Publishers.LogError<Self> {
        .init(upstream: self, logMessage: message, logFunc: logFunc)
    }
}

extension Publishers {
    struct LogError<Upstream: Publisher>: Publisher {
        typealias Output = Upstream.Output
        typealias Failure = Upstream.Failure
        
        private let upstream: Upstream
        private let logMessage: String
        private let logFunc: (String) -> Void
        
        init(upstream: Upstream, logMessage: String, logFunc: @escaping (String) -> Void) {
            self.upstream = upstream
            self.logMessage = logMessage
            self.logFunc = logFunc
        }
        
        func receive<S: Subscriber>(subscriber: S) where S.Failure == Upstream.Failure, S.Input == Upstream.Output {
            self.upstream.handleEvents(receiveCompletion: { result in
                guard case .failure(let error) = result else { return }
                logFunc("\(logMessage): \(error.localizedDescription)")
            })
            .subscribe(subscriber)
        }
    }
}
