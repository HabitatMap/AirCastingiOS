// Created by Lunar on 27/01/2022.
//
import Foundation
import Resolver

class TurnOnLocationFixedViewModel: ObservableObject {
    
    @Published var isConfirmCreatingSessionActive: Bool = false
    @Published var isLocationSessionDetailsActive: Bool = false
    @Published var alert: AlertInfo?
    
    private let sessionContext: CreateSessionContext
    @Injected private var locationHandler: LocationHandler
    @Injected private var urlProvider: URLProvider
    
    var shouldShowAlert: Bool {
        return locationHandler.isLocationDenied()
    }
    
    var getSessionName: String {
        return sessionContext.sessionName ?? ""
    }
    
    init(sessionContext: CreateSessionContext) {
        self.sessionContext = sessionContext
    }
    
    func requestLocationAuthorisation() {
        locationHandler.requestAuthorisation()
    }
    
    func onButtonClick() {
        switch shouldShowAlert {
        case true:
            alert = InAppAlerts.locationAlert()
        case false:
            isLocationSessionDetailsActive = !(sessionContext.isIndoor ?? true)
            isConfirmCreatingSessionActive = sessionContext.isIndoor ?? true
        }
    }
}
