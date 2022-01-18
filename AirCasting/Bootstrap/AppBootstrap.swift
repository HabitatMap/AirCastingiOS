// Created by Lunar on 13/09/2021.
//

import Foundation
import Resolver

class AppBootstrap {
    @Injected private var firstRunInfoProvider: FirstRunInfoProvidable
    @Injected private var deauthorizable: Deauthorizable
    
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
