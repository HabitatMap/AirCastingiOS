// Created by Lunar on 26/07/2021.
//

import Combine
import Foundation

extension Publisher {
    func onError(_ perform: @escaping (Failure) -> Void) -> Publishers.OnError<Self> {
        .init(upstream: self, handler: perform)
    }
}

extension Publishers {
    struct OnError<Upstream: Publisher>: Publisher {
        typealias Output = Upstream.Output
        typealias Failure = Upstream.Failure
        
        private let upstream: Upstream
        private let handler: (Failure) -> Void
        
        init(upstream: Upstream, handler: @escaping (Failure) -> Void) {
            self.upstream = upstream
            self.handler = handler
        }
        
        func receive<S>(subscriber: S) where S : Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input {
            self.upstream.handleEvents(receiveCompletion: {
                switch $0 {
                case .failure(let error):
                    if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                        return
                    }
                    self.handler(error)
                case .finished: break
                }
            }).subscribe(subscriber)
        }
    }
}

