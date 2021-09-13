// Created by Lunar on 13/09/2021.
//

import Foundation

class AppBootstrap {
    private let firstRunInfoProvider: FirstRunInfoProvidable
    private let deauthorizable: Deauthorizable
    
    init(firstRunInfoProvider: FirstRunInfoProvidable, deauthorizable: Deauthorizable) {
        self.firstRunInfoProvider = firstRunInfoProvider
        self.deauthorizable = deauthorizable
    }
    
    func bootstrap() {
        if firstRunInfoProvider.isFirstAppLaunch {
            handleFirstAppLaunch()
        }
        firstRunInfoProvider.registerAppLaunch()
    }
    
    private func handleFirstAppLaunch() {
        print("First launch detected, clearing authentication data")
        try? deauthorizable.deauthorize()
    }
}
