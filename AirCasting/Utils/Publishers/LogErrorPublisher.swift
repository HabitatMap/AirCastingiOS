// Created by Lunar on 16/06/2021.
//

import Combine

extension Publisher {
    /// Logs any error ending the upstream using provided logging function.
    /// - Parameters:
    ///   - message: A message that will prefix the `error.localizedDescription` printout.
    ///   - logFunc: Optional custom logging function.
    /// - Returns: A publisher that matches upstream `Output` and `Failure` types.
    func logError(message: String = "",
                  file: String = #file,
                  function: String = #function,
                  line: Int = #line,
                  logFunc: @escaping Publishers.Logging.LogFunc = { Log.error($0, file: $1, function: $2, line: $3) }) -> Publishers.LogError<Self> {
        return .init(upstream: self, logMessage: message, file: file, function: function, line: line, logFunc: logFunc)
    }
}

extension Publishers {
    struct LogError<Upstream: Publisher>: Publisher {
        typealias Output = Upstream.Output
        typealias Failure = Upstream.Failure
        
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
        
        func receive<S: Subscriber>(subscriber: S) where S.Failure == Upstream.Failure, S.Input == Upstream.Output {
            self.upstream.handleEvents(receiveCompletion: { result in
                guard case .failure(let error) = result else { return }
                logFunc("\(logMessage): \(error.localizedDescription)", file, function, line)
            })
            .subscribe(subscriber)
        }
    }
}

extension Publishers {
    enum Logging {
        typealias LogFunc = (_ text: String, _ file: String, _ function: String, _ line: Int) -> Void
    }
}
