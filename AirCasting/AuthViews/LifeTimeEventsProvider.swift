// Created by Lunar on 07/07/2021.
//

import Foundation

class LifeTimeEventsProvider: ObservableObject {
    private let userDefaults: UserDefaults
    private static let wasAlreadyLaunchedInThePastKey = "FirstRunInfoProvider.wasAlreadyLaunchedInThePastKey"
    
    var hasEverLoggedIn: Bool {
        set {
            objectWillChange.send()
            userDefaults.setValue(newValue, forKey: "hasEverLoggedIn")
        }
        get {
            userDefaults.bool(forKey: "hasEverLoggedIn")
        }
    }
    
    var hasEverPassedOnBoarding: Bool {
        set {
            objectWillChange.send()
            userDefaults.setValue(newValue, forKey: "onBoardingKey")
        }
        get {
            userDefaults.bool(forKey: "onBoardingKey")
        }
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
}


extension LifeTimeEventsProvider: FirstRunInfoProvidable {
    var isFirstAppLaunch: Bool {
        !userDefaults.bool(forKey: Self.wasAlreadyLaunchedInThePastKey)
    }
    
    func registerAppLaunch() {
        userDefaults.set(true, forKey: Self.wasAlreadyLaunchedInThePastKey)
    }
}
