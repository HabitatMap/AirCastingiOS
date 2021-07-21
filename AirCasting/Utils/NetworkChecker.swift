// Created by Lunar on 08/07/2021.
//

import Foundation
import Network

protocol CheckNetwork {
    func monitorNetwork()
}

final class NetworkChecker: CheckNetwork {
    @Published var connectionAvailable: Bool = false
    let monitor = NWPathMonitor()
    
    func monitorNetwork() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                Log.info("Current devise has an network connection")
                print("Current devise has an network connection")
                self.connectionAvailable = true
            } else {
                Log.info("Current devise does not have an network connection")
                print("Current devise DOES NOT have an network connection")
                self.connectionAvailable = false
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}

final class DummyNetworkChecker: CheckNetwork {
    func monitorNetwork() {
        Log.info("Current devise has an network connection")
        print("Current devise has an network connection")
    }
}
