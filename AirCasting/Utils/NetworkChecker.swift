// Created by Lunar on 08/07/2021.
//

import Foundation
import Network

protocol NetworkStatusPresenter {
    var connectionAvailable: Bool { get }
}

final class NetworkChecker: NetworkStatusPresenter, ObservableObject {
    var connectionAvailable: Bool
    private let monitor = NWPathMonitor()

    init(connectionAvailable: Bool) {
        self.connectionAvailable = connectionAvailable
        monitorNetwork()
    }

    private func monitorNetwork() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                Log.info("Current devise has a network connection")
                print(Strings.NetworkChecker.satisfiedPathText)
                self.connectionAvailable = true
            } else {
                Log.info("Current devise does not have an network connection")
                print(Strings.NetworkChecker.failurePathText)
                self.connectionAvailable = false
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}

final class DummyNetworkChecker: NetworkStatusPresenter {
    var connectionAvailable: Bool

    init(connectionAvailable: Bool) {
        self.connectionAvailable = connectionAvailable
    }
}
