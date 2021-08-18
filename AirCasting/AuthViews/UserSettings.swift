// Created by Lunar on 16/07/2021.
//

import Foundation

class UserSettings: ObservableObject {
    private let userDefaults: UserDefaults
    
    var contributingToCrowdMap: Bool {
        set {
            objectWillChange.send()
            userDefaults.setValue(newValue, forKey: "crowdMap")
        }
        get {
            userDefaults.bool(forKey: "crowdMap")
        }
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}
