// Created by Lunar on 16/07/2021.
//

import Foundation
import UIKit
import Resolver

class UserSettings: ObservableObject {
    private let userDefaults: UserDefaults
    private let crowdMapKey = Constants.UserDefaultsKeys.crowdMap
    private let locationlessKey = Constants.UserDefaultsKeys.disableMapping
    private let keepScreenOnKey = Constants.UserDefaultsKeys.keepScreenOn
    @Injected private var featureFlagProvider: FeatureFlagProvider
    private let convertToCelsiusKey = Constants.UserDefaultsKeys.convertToCelsius
    private let satteliteMapKey = Constants.UserDefaultsKeys.satelliteMapKey

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
    
    var satteliteMap: Bool {
        get {
            userDefaults.bool(forKey: satteliteMapKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: satteliteMapKey)
            Log.info("Changed satellite setting to \(satteliteMap ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        contributingToCrowdMap = userDefaults.valueExists(forKey: crowdMapKey) ? userDefaults.bool(forKey: crowdMapKey) : true
        keepScreenOn = userDefaults.bool(forKey: keepScreenOnKey)
        // This is included in case user turns on disable mapping but we turn off the feature, because otherwise the user could never turn this off
        let isFeatureFlagOn = featureFlagProvider.isFeatureOn(.locationlessSessions) ?? false
        disableMapping = isFeatureFlagOn ? userDefaults.bool(forKey: locationlessKey) : false
        convertToCelsius = userDefaults.bool(forKey: convertToCelsiusKey)
        satteliteMap = userDefaults.bool(forKey: satteliteMapKey)
    }
}
