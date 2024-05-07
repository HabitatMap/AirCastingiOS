// Created by Lunar on 28/06/2021.
//

import Foundation

class UserDefaultsURLProvider: URLProvider {
    var baseAppURL: URL {
        get {
            userDefaults.url(forKey: "baseURL") ?? URL(string: "http://45.56.103.151")!
        }
        set {
            userDefaults.set(newValue, forKey: "baseURL")
        }
    }
    
    private let userDefaults: UserDefaults
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}
