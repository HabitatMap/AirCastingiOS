// Created by Lunar on 16/07/2021.
//

import Foundation
import UIKit

class UserSettings: ObservableObject {
    private let userDefaults: UserDefaults
    private let crowdMapKey = Constants.UserDefaultsKeys.crowdMap
    private let convertToCelsiusKey = Constants.UserDefaultsKeys.convertToCelsius
    
    var contributingToCrowdMap: Bool {
        get {
            userDefaults.bool(forKey: crowdMapKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: crowdMapKey)
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
    
    var convertToCelsius: Bool {
        get {
            userDefaults.bool(forKey: convertToCelsiusKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: convertToCelsiusKey)
            Log.info("Changed convert to celcius setting to \(convertToCelsius ? "ON" : "OFF")")
        }
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        contributingToCrowdMap = userDefaults.valueExists(forKey: crowdMapKey) ? userDefaults.bool(forKey: crowdMapKey) : true
        keepScreenOn = userDefaults.bool(forKey: "keepScreenOn")
        keepScreenOn = userDefaults.bool(forKey: convertToCelsiusKey)
    }
}
