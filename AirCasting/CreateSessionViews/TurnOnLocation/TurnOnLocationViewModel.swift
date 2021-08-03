// Created by Lunar on 02/08/2021.
//

import Foundation

class TurnOnLocationViewModel {
    
    private var locationTracker: LocationTracker
    private var sessionContext: CreateSessionContext
    
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
    
    init(locationTracker: LocationTracker, sessionContext: CreateSessionContext) {
        self.locationTracker = locationTracker
        self.sessionContext = sessionContext
    }
    
    func requestLocation() {
        locationTracker.requestAuthorisation()
    }
}

#if DEBUG
class DummyTurnOnLocationViewModel: TurnOnLocationViewModel {
    
}
#endif
