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
    
    private let userDefaults: UserDefaults
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}

class UserDefaultsSynchronizationState: isSessionSynchronizing {
    
        var syncIsInProgress: Bool {
            set {
                userDefaults.set(newValue, forKey: "sessionSynchronization")
            }
            get {
                userDefaults.bool(forKey: "sessionSynchronization")
            }
        }
    
    private let userDefaults: UserDefaults
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}
