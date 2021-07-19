// Created by Lunar on 08/07/2021.
//

import Foundation
import Network

final class NetworkChecker {
    @Published var connectionAvailable: Bool
    static let shared = NetworkChecker(connectionAvailable: false)
    let monitor = NWPathMonitor()
    
    init(connectionAvailable: Bool) {
        self.connectionAvailable = connectionAvailable
    }
    
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
