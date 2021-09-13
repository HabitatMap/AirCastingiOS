// Created by Lunar on 13/09/2021.
//

import Foundation

class FirstRunInfoProvider: FirstRunInfoProvidable {
    private let userDefaults: UserDefaults
    
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    
}
