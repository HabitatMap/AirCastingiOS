// Created by Lunar on 28/06/2021.
//

import Foundation

class UserDefaultsBaseURLProvider: BaseURLProvider {
    var baseAppURL: URL {
        set {
            userDefaults.set(newValue, forKey: "baseURL")
        }
        get {
            userDefaults.url(forKey: "baseURL") ?? URL(string: "http://aircasting.org/api")!
        }
    }
    
    var didAppEnterBackground: Bool {
        set {
            userDefaults.set(newValue, forKey: "Background")
        }
        get {
            userDefaults.bool(forKey: "Background")
        }
    }
    
    private let userDefaults: UserDefaults
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}
