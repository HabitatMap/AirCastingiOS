// Created by Lunar on 08/07/2021.
//

import Foundation
import Network

protocol NetworkStatusChecking {
    func monitorNetwork() 
}

final class NetworkChecker: NetworkStatusChecking {
    func monitorNetwork() {
        monitorNetwork { result in
            switch result {
            case NetworkSates.connected:
                Log.info("Current devise has an network connection")
                print("Current devise has an network connection")
            case NetworkSates.disconnected:
                Log.info("Current devise does not have an network connection")
                print("Current devise DOES NOT have an network connection")
            }
        }
    }
    
    let shared = NetworkChecker()
    let monitor = NWPathMonitor()
    
    func monitorNetwork(completion: @escaping (NetworkSates) -> ()) {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                completion(.connected)
            } else {
                completion(.disconnected)
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}
