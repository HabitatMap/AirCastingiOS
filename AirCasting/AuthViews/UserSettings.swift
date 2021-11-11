// Created by Lunar on 16/07/2021.
//

import Foundation
import UIKit

class UserSettings: ObservableObject {
    private let userDefaults: UserDefaults
    
    var contributingToCrowdMap: Bool {
        get {
            userDefaults.bool(forKey: "crowdMap")
        }
        set {
            userDefaults.setValue(newValue, forKey: "crowdMap")
            Log.info("Changed crowdMap contribution setting to \(contributingToCrowdMap ? "ON" : "OFF")")
        }
    }
    
    var keepScreenOn: Bool {
        get {
            userDefaults.bool(forKey: "keepScreenOn")
        }
        set {
            userDefaults.setValue(newValue, forKey: "keepScreenOn")
            UIApplication.shared.isIdleTimerDisabled = userDefaults.bool(forKey: "keepScreenOn")
            Log.info("Changed keepScreenOn setting to \(keepScreenOn ? "ON" : "OFF")")
        }
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        contributingToCrowdMap = true
        keepScreenOn = userDefaults.bool(forKey: "keepScreenOn")
    }
}
