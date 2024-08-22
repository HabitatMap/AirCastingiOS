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
    private let darkThemeKey = Constants.UserDefaultsKeys.darkTheme
    private let convertToCelsiusKey = Constants.UserDefaultsKeys.convertToCelsius
    private let satteliteMapKey = Constants.UserDefaultsKeys.satelliteMapKey
    private let twentyFourHourFormatKey = Constants.UserDefaultsKeys.twentyFourHoursFormatKey
    private let syncOnlyThroughWifiKey = Constants.UserDefaultsKeys.syncOnlyThroughWifi
    private let dormantSessionsAlertKey = Constants.UserDefaultsKeys.dormantSessionsAlert
    @Injected private var featureFlagProvider: FeatureFlagProvider

    var contributingToCrowdMap: Bool {
        get {
            userDefaults.bool(forKey: crowdMapKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: crowdMapKey)
            Log.info("Changed crowdMap contribution setting to \(self.contributingToCrowdMap ? "ON" : "OFF")")
        }
    }
    
    var keepScreenOn: Bool {
        get {
            userDefaults.bool(forKey: keepScreenOnKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: keepScreenOnKey)
            UIApplication.shared.isIdleTimerDisabled = userDefaults.bool(forKey: keepScreenOnKey)
            Log.info("Changed keepScreenOn setting to \(self.keepScreenOn ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }
    
    var darkTheme: Bool {
        get {
            userDefaults.bool(forKey: darkThemeKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: darkThemeKey)
            UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.overrideUserInterfaceStyle = newValue ? .dark : .light
            Log.info("Changed darkTheme setting to \(self.darkTheme ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }
    
    var disableMapping: Bool {
        get {
            userDefaults.bool(forKey: locationlessKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: locationlessKey)
            Log.info("Changed locationless sessions setting to \(self.disableMapping ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }
    
    var convertToCelsius: Bool {
        get {
            userDefaults.bool(forKey: convertToCelsiusKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: convertToCelsiusKey)
            Log.info("Changed convert to celcius setting to \(self.convertToCelsius ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }

    var satteliteMap: Bool {
        get {
            userDefaults.bool(forKey: satteliteMapKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: satteliteMapKey)
            Log.info("Changed satellite setting to \(self.satteliteMap ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }
    
    var twentyFourHour: Bool {
        get {
            userDefaults.bool(forKey: twentyFourHourFormatKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: twentyFourHourFormatKey)
            Log.info("Changed twenty four hour format to \(self.twentyFourHour ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }
    
    var syncOnlyThroughWifi: Bool {
        get {
            userDefaults.bool(forKey: syncOnlyThroughWifiKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: syncOnlyThroughWifiKey)
            Log.info("Changed sync only through wifi to \(self.syncOnlyThroughWifi ? "ON" : "OFF")")
            objectWillChange.send()
        }
    }
    
    var dormantSessionsAlert: Bool {
        get {
            userDefaults.bool(forKey: dormantSessionsAlertKey)
        }
        set {
            userDefaults.setValue(newValue, forKey: dormantSessionsAlertKey)
            Log.info("Changed dormant sessions alert to \(self.dormantSessionsAlert ? "ON" : "OFF")")
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
        twentyFourHour = userDefaults.valueExists(forKey: twentyFourHourFormatKey) ? userDefaults.bool(forKey: twentyFourHourFormatKey) : true
        syncOnlyThroughWifi = userDefaults.bool(forKey: syncOnlyThroughWifiKey)
        dormantSessionsAlert = userDefaults.bool(forKey: dormantSessionsAlertKey)
    }
}
