// Created by Lunar on 13/09/2021.
//

import Foundation
import Resolver
import GoogleMaps
import GooglePlaces

class AppBootstrap {
    @Injected private var firstRunInfoProvider: FirstRunInfoProvidable
    @Injected private var deauthorizable: Deauthorizable
    
    func bootstrap() {
        if firstRunInfoProvider.isFirstAppLaunch {
            handleFirstAppLaunch()
        }
        firstRunInfoProvider.registerAppLaunch()
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_PLACES_KEY)
    }
    
    private func handleFirstAppLaunch() {
        Log.info("First launch detected, clearing authentication data")
        try? deauthorizable.deauthorize()
    }
}
