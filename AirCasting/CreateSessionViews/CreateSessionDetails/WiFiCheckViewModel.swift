// Created by Lunar on 25/08/2022.
//

import Foundation
import NetworkExtension
import SwiftUI

class WiFiCheckViewModel: ObservableObject {
    let wifiSSID: String
    let wifiPassword: String
    
    let hotspotManager = NEHotspotConfigurationManager.shared
    var wiFiConfig: NEHotspotConfiguration
    
    @Published var finalColor: Color = .black
    
    init(wifiSSID: String, wifiPassword: String) {
        self.wifiSSID = wifiSSID
        self.wifiPassword = wifiPassword
        self.wiFiConfig = .init(ssid: wifiSSID, passphrase: wifiPassword, isWEP: false)
    }
    
    func connectToWiFi() {
        self.hotspotManager.removeConfiguration(forSSID: self.wifiSSID)
        hotspotManager.apply(wiFiConfig) { error in
            if let error = error {
                guard error.localizedDescription == "already associated." else {
                    self.finalColor = .red
                    Log.info("\(error.localizedDescription)")
                    return
                }
                self.finalColor = .green
            }
            else {
                self.finalColor = .green
                self.hotspotManager.removeConfiguration(forSSID: self.wifiSSID)
            }
        }
    }
}
