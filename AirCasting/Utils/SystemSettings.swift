// Created by Lunar on 15/07/2021.
//

import Foundation
import SwiftUI

enum BluetoothSettingsType {
    case app
    case global
}

protocol SettingsRedirection {
    func goToLocationAuthSettings()
    func goToBluetoothSettings(type: BluetoothSettingsType)
}

final class DefaultSettingsRedirection: SettingsRedirection {
    func goToLocationAuthSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            let app = UIApplication.shared
            if app.canOpenURL(url) {
                app.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func goToBluetoothSettings(type: BluetoothSettingsType) {
        var url: URL!
        switch type {
        case .global: url = URL(string: "App-prefs:root=Bluetooth")
        case .app: url = URL(string: UIApplication.openSettingsURLString)
        }
        let app = UIApplication.shared
        if app.canOpenURL(url) {
            app.open(url, options: [:], completionHandler: nil)
        }
    }
}
