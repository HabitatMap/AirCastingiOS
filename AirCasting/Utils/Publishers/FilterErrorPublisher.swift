// Created by Lunar on 26/07/2021.
//

import Combine
import Foundation

extension Publisher {
    func filterError(_ filter: @escaping (Failure) -> Bool) -> Publishers.FilterError<Self> {
        .init(upstream: self, filter: filter)
    }
}

extension Publishers {
    struct FilterError<Upstream: Publisher>: Publisher {
        typealias Output = Upstream.Output
        typealias Failure = Upstream.Failure
        
        private let upstream: Upstream
        private let filter: (Failure) -> Bool
        
        init(upstream: Upstream, filter: @escaping (Failure) -> Bool) {
            self.upstream = upstream
            self.filter = filter
        }
        
        func receive<S>(subscriber: S) where S : Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input {
            upstream.catch { error -> AnyPublisher<Output, Failure> in
                guard filter(error) else {
                    return Empty().eraseToAnyPublisher()
                }
                return Fail(error: error).eraseToAnyPublisher()
            }.subscribe(subscriber)
        }
    }
}
