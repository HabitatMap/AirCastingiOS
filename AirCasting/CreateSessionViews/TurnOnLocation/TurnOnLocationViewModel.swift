// Created by Lunar on 02/08/2021.
//

import Foundation

class TurnOnLocationViewModel {
    
    private let locationHandler: LocationHandler
    private let bluetoothHandler: BluetoothHandler
    private let sessionContext: CreateSessionContext
    private let urlProvider: BaseURLProvider
    
    var passURLProvider: BaseURLProvider {
        return urlProvider
    }
    
    var shouldShowAlert: Bool {
        return locationHandler.isLocationDenied()
    }
    
    var disableButton: Bool {
        return locationHandler.isLocationDenied()
    }
    
    var isMobileSession: Bool {
        return sessionContext.sessionType == .mobile
    }
    
    var getSessionContext: CreateSessionContext {
        return sessionContext
    }
    
    init(locationHandler: LocationHandler, bluetoothHandler: BluetoothHandler, sessionContext: CreateSessionContext, urlProvider: BaseURLProvider) {
        self.locationHandler = locationHandler
        self.bluetoothHandler = bluetoothHandler
        self.sessionContext = sessionContext
        self.urlProvider = urlProvider
    }
    
    func requestLocationAuthorisation() {
        locationHandler.requestAuthorisation()
    }
    
    func checkIfBluetoothDenied() -> Bool {
       return bluetoothHandler.isBluetoothDenied()
    }
}
