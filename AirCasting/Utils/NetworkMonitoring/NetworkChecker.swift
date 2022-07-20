// Created by Lunar on 08/07/2021.
//

import Foundation
import Network

protocol NetworkChecker {
    var connectionAvailable: Bool { get }
    var isUsingWifi: Bool { get }
}

final class DefaultNetworkChecker: NetworkChecker {
    var connectionAvailable: Bool = false
    var isUsingWifi: Bool = false
    private let monitor = NWPathMonitor()

    init() {
        monitorNetwork()
    }

    private func monitorNetwork() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                Log.info(Strings.NetworkChecker.satisfiedPathText)
                self.connectionAvailable = true
                self.isUsingWifi = path.usesInterfaceType(.wifi)
                Log.info("CHANGED WIFI STATUS TO: \(self.isUsingWifi)")
            } else {
                Log.info(Strings.NetworkChecker.failurePathText)
                self.connectionAvailable = false
                self.isUsingWifi = false
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}

final class DummyNetworkChecker: NetworkChecker {
    var connectionAvailable: Bool
    var isUsingWifi: Bool = false

    init(connectionAvailable: Bool) {
        self.connectionAvailable = connectionAvailable
    }
}
