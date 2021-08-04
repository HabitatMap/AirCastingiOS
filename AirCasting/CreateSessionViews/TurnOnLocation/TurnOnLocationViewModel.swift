// Created by Lunar on 02/08/2021.
//

import Foundation

class TurnOnLocationViewModel {
    
    var locationTracker: LocationTracker
    var sessionContext: CreateSessionContext
    let urlProvider: BaseURLProvider
    
    var shouldShowAlert: Bool {
        return locationTracker.locationGranted == .denied
    }
    
    var disableButton: Bool {
        return locationTracker.locationGranted == .denied
    }
    
    var mobileSessionContext: Bool {
        return sessionContext.sessionType == .mobile
    }
    
    var getSessionContext: CreateSessionContext {
        return sessionContext
    }
    
    init(locationTracker: LocationTracker, sessionContext: CreateSessionContext, urlProvider: BaseURLProvider) {
        self.locationTracker = locationTracker
        self.sessionContext = sessionContext
        self.urlProvider = urlProvider
    }
    
    func requestLocation() {
        locationTracker.requestAuthorisation()
    }
}
