// Created by Lunar on 08/07/2021.
//

import Foundation
import Network

protocol NetworkChecker {
    var connectionAvailable: Bool { get }
}

final class DefaultNetworkChecker: NetworkChecker {
    var connectionAvailable: Bool = false
    private let monitor = NWPathMonitor()

    init() {
        monitorNetwork()
    }

    private func monitorNetwork() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                Log.info(Strings.NetworkChecker.satisfiedPathText)
                self.connectionAvailable = true
            } else {
                Log.info(Strings.NetworkChecker.failurePathText)
                self.connectionAvailable = false
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}

final class DummyNetworkChecker: NetworkChecker {
    var connectionAvailable: Bool

    init(connectionAvailable: Bool) {
        self.connectionAvailable = connectionAvailable
    }
}
