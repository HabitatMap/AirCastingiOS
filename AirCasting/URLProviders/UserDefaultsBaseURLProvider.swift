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
    
    var baseAppURLwithoutPort: URL {
        set {
            userDefaults.set(newValue, forKey: "baseURLwithoutPort")
        }
        get {
            userDefaults.url(forKey: "baseURLwithoutPort") ?? URL(string: "http://aircasting.org/api")!
        }
    }
    
    var baseAppPort: URL {
        set {
            userDefaults.set(newValue, forKey: "basePort")
        }
        get {
            userDefaults.url(forKey: "basePort") ?? URL(string: "80")!
        }
    }
    
    private let userDefaults: UserDefaults
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}
