// Created by Lunar on 28/06/2021.
//

import Foundation

class UserDefaultsBaseURLProvider: BaseURLProvider, ObservableObject {
    var baseAppURL: URL {
        set {
            userDefaults.set(newValue, forKey: "baseURL")
        }
        get {
            userDefaults.url(forKey: "baseURL") ?? URL(string: "http://aircasting.org/")!
        }
    }
    
    private let userDefaults: UserDefaults
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}
