// Created by Lunar on 16/07/2021.
//

import Foundation
import UIKit

class UserSettings: ObservableObject {
    private let userDefaults: UserDefaults
    private let crowdMapKey = Constants.UserDefaultsKeys.crowdMap
    private let locationlessKey = Constants.UserDefaultsKeys.disableMapping
    private let keepScreenOnKey = Constants.UserDefaultsKeys.keepScreenOn
    private let featureFlagsViewModel = FeatureFlagsViewModel.shared
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
            userDefaults.bool(forKey: keepScreenOnKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: keepScreenOnKey)
            UIApplication.shared.isIdleTimerDisabled = userDefaults.bool(forKey: keepScreenOnKey)
            Log.info("Changed keepScreenOn setting to \(keepScreenOn ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }

    var disableMapping: Bool {
        get {
            userDefaults.bool(forKey: locationlessKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: locationlessKey)
            Log.info("Changed locationless sessions setting to \(disableMapping ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }

    var convertToCelsius: Bool {
        get {
            userDefaults.bool(forKey: convertToCelsiusKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: convertToCelsiusKey)
            Log.info("Changed convert to celcius setting to \(convertToCelsius ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        contributingToCrowdMap = userDefaults.valueExists(forKey: crowdMapKey) ? userDefaults.bool(forKey: crowdMapKey) : true
        keepScreenOn = userDefaults.bool(forKey: keepScreenOnKey)
        // This is included in case user turns on disable mapping but we turn off the feature, because otherwise the user could never turn this off
        disableMapping = featureFlagsViewModel.enabledFeatures.contains(.locationlessSessions) ? userDefaults.bool(forKey: locationlessKey) : false
        convertToCelsius = userDefaults.bool(forKey: convertToCelsiusKey)
    }
}
