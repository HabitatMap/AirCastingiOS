// Created by Lunar on 16/07/2021.
//

import Foundation

class UserSettings: ObservableObject {
    private let userDefaults: UserDefaults
    
    @Published var contributingToCrowdMap: Bool {
        didSet {
            Log.info("Changed crowdmap contribution setting to \(contributingToCrowdMap ? "ON" : "OFF")")
            userDefaults.setValue(contributingToCrowdMap, forKey: "crowdMap")
        }
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.contributingToCrowdMap = userDefaults.bool(forKey: "crowdMap")
        self.userDefaults = userDefaults
    }
}
