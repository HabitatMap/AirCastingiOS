// Created by Lunar on 22/04/2021.
//

import Foundation
import SwiftUI

class SettingsManager {
    static func goToAuthSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            Log.error("Couldn't get settings url")
            return
        }
        let app = UIApplication.shared
        if app.canOpenURL(url) {
            app.open(url, options: [:], completionHandler: nil)
        }
    }
}
