// Created by Lunar on 13/09/2021.
//

import Foundation
import Resolver
import GoogleMaps
import GooglePlaces
import FirebaseCrashlytics

class AppBootstrap {
    @Injected private var firstRunInfoProvider: FirstRunInfoProvidable
    @Injected private var deauthorizable: Deauthorizable
    @Injected private var averagingService: AveragingService
    
    func bootstrap() {
        if firstRunInfoProvider.isFirstAppLaunch {
            handleFirstAppLaunch()
        }
        #if BETA
        Crashlytics.crashlytics().setCustomValue("BETA", forKey: "build_type")
        #elseif RELEASE
        Crashlytics.crashlytics().setCustomValue("RELEASE", forKey: "build_type")
        #endif
        firstRunInfoProvider.registerAppLaunch()
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_PLACES_KEY)
        averagingService.start()
    }
    
    private func handleFirstAppLaunch() {
        Log.info("First launch detected, clearing authentication data")
        try? deauthorizable.deauthorize()
    }
}
