// Created by Lunar on 02/08/2021.
//

import Foundation

protocol TurnOnLocationRequirements {
    var locationTracker: LocationTracker { get }
    var sessionContext: CreateSessionContext { get }
}

class TurnOnLocationViewModel: TurnOnLocationRequirements {
    
    var locationTracker: LocationTracker
    var sessionContext: CreateSessionContext
    
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
struct DummyTurnOnLocationViewModel {
}
#endif
