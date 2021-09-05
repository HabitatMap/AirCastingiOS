// Created by Lunar on 16/07/2021.
//

import Foundation

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
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        contributingToCrowdMap = true
    }
}
