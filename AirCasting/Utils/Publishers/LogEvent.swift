// Created by Lunar on 16/06/2021.
//

import Combine

extension Publisher {
    /// Logs a string litral to `verbose` output.
    /// - Parameters:
    ///   - message: A string literal to be logged.
    ///   - logFunc: Optional custom logging function.
    ///   - stringToLog: A `String` to be logged
    /// - Returns: A publisher that matches upstream `Output` and `Failure` types.
    ///
    /// Note: This function is used when one doesn't need an output value to perform logging, for example:
    /// ~~~
    /// urlSession
    ///    .dataTaskPublisher(for: url)
    ///    .logVerbose("Data received!")
    ///    .sink()
    ///~~~
    func logVerbose(message: StringLiteralType, _ logFunc: @escaping (_ stringToLog: String) -> Void = { Log.verbose($0) }) -> Publishers.LogEvent<Self> {
        .init(upstream: self, logMessageClosure: { _ in message }, logFunc: logFunc)
    }
    
    /// Logs a string to `verbose` output
    /// - Parameters:
    ///   - messageClosure: A message closure that will be executed to determine logged string.
    ///   - output: Upstream element to be used for logging
    ///   - logFunc: Optional custom logging function
    ///   - stringToLog: A `String` to be logged
    /// - Returns: A publisher that matches upstream `Output` and `Failure` types.
    ///
    /// Note: This function is used when one doesn't need an output value to perform logging, for example:
    /// ~~~
    /// urlSession
    ///    .dataTaskPublisher(for: url)
    ///    .decode(type: [String].self, decoder: JSONDecoder())
    ///    .logVerbose("Received \($0.count) values!")
    ///    .sink()
    ///~~~
    func logVerbose(_ messageClosure: @escaping (_ output: Output) -> String, _ logFunc: @escaping (_ stringToLog: String) -> Void = { Log.verbose($0) }) -> Publishers.LogEvent<Self> {
        .init(upstream: self, logMessageClosure: messageClosure, logFunc: logFunc)
    }
}

extension Publishers {
    struct LogEvent<Upstream: Publisher>: Publisher {
        typealias Output = Upstream.Output
        typealias Failure = Upstream.Failure
        
        private let upstream: Upstream
        private let logFunc: (String) -> Void
        private let logMessageClosure: (Output) -> String
        
        init(upstream: Upstream, logMessageClosure: @escaping (Output) -> String, logFunc: @escaping (String) -> Void) {
            self.upstream = upstream
            self.logMessageClosure = logMessageClosure
            self.logFunc = logFunc
        }
        
        func receive<S: Subscriber>(subscriber: S) where S.Failure == Upstream.Failure, S.Input == Upstream.Output {
            upstream.handleEvents(receiveOutput: {
                logFunc("\(logMessageClosure($0))")
            })
            .subscribe(subscriber)
        }
    }
}
