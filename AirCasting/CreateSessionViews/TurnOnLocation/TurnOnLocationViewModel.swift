// Created by Lunar on 02/08/2021.
//

import Foundation

class TurnOnLocationViewModel {
    
    let locationHandler: LocationHandler
    let bluetoothHandler: BluetoothHandler
    let sessionContext: CreateSessionContext
    let urlProvider: BaseURLProvider
    
    var mobileSessionContext: Bool {
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
}
