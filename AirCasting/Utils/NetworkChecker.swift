// Created by Lunar on 08/07/2021.
//

import Foundation
import Network

class NetworkChecker {
    static let shared = NetworkChecker()
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
