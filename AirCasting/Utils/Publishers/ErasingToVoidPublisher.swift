// Created by Lunar on 16/06/2021.
//

import Foundation
import Combine

extension Publisher {
    /// Will map output values to `Void`.
    /// - Returns: A publisher that matches the upstream `Failure` and has an `Ouput` set to `Void`.
    func eraseToVoid() -> Publishers.ErasingToVoid<Self> {
        .init(upstream: self)
    }
}

extension Publishers {
    struct ErasingToVoid<Upstream: Publisher>: Publisher {
        typealias Output = Void
        typealias Failure = Upstream.Failure
        
        private let upstream: Upstream
        
        init(upstream: Upstream) {
            self.upstream = upstream
        }
        
        func receive<S>(subscriber: S) where S : Subscriber, Upstream.Failure == S.Failure, Void == S.Input {
            self.upstream.map { _ in return Void() }.subscribe(subscriber)
        }
    }
}
