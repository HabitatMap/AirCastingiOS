// Created by Lunar on 15/07/2021.
//

import Foundation
import SwiftUI

protocol SettingsRedirection {
    func goToLocationAuthSettings()
    func goToAppsBluetoothAuthSettings()
}

extension SettingsRedirection {
    func goToLocationAuthSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            let app = UIApplication.shared
            if app.canOpenURL(url) {
                app.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func goToAppsBluetoothAuthSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            let app = UIApplication.shared
            if app.canOpenURL(url) {
                app.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func goToBluetoothAuthSettings() {
        if let url = URL(string: "App-prefs:root=Bluetooth") {
            let app = UIApplication.shared
            if app.canOpenURL(url) {
                app.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

final class DefaultSettingsRedirection: SettingsRedirection, ObservableObject { }
