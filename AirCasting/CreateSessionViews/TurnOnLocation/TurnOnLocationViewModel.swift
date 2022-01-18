// Created by Lunar on 02/08/2021.
//

import Foundation
import Resolver

// [RESOLVER] Init this VM inside View
class TurnOnLocationViewModel: ObservableObject {
    @Published var isPowerABLinkActive = false
    @Published var isTurnBluetoothOnLinkActive = false
    @Published var isMobileLinkActive = false
    @Published var restartABLink = false
    @Published var alert: AlertInfo?
    var isSDClearProcess: Bool
    
    @Injected private var locationHandler: LocationHandler
    @Injected private var bluetoothHandler: BluetoothHandler
    private let sessionContext: CreateSessionContext
    
    var shouldShowAlert: Bool {
        return locationHandler.isLocationDenied()
    }
    
    var isMobileSession: Bool {
        return sessionContext.sessionType == .mobile
    }
    
    var getSessionContext: CreateSessionContext {
        return sessionContext
    }
    
    init(sessionContext: CreateSessionContext, isSDClearProcess: Bool) {
        self.sessionContext = sessionContext
        self.isSDClearProcess = isSDClearProcess
    }
    
    func requestLocationAuthorisation() {
        locationHandler.requestAuthorisation()
    }
    
    func checkIfBluetoothDenied() -> Bool {
       return bluetoothHandler.isBluetoothDenied()
    }
    
    func onButtonClick() {
        switch shouldShowAlert {
        case true:
            alert = InAppAlerts.locationAlert()
        case false:
            locationOnStep()
        }
    }
    
    private func locationOnStep() {
        isMobileSession ? isMobileLinkActive = true : notMobileSessionStep()
    }
    
    private func notMobileSessionStep() {
        checkIfBluetoothDenied() ? isTurnBluetoothOnLinkActive = true : SDClearProcess()
    }
    
    private func SDClearProcess() {
        isSDClearProcess ? restartABLink.toggle() : isPowerABLinkActive.toggle()
    }
}
