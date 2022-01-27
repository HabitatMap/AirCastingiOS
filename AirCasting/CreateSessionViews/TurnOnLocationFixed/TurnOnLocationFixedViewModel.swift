// Created by Lunar on 27/01/2022.
//
import Foundation

class TurnOnLocationFixedViewModel: ObservableObject {
    
    @Published var isConfirmCreatingSessionActive: Bool = false
    @Published var isLocationSessionDetailsActive: Bool = false
    @Published var alert: AlertInfo?
    
    private let locationHandler: LocationHandler
    private let sessionContext: CreateSessionContext
    private let urlProvider: BaseURLProvider
    
    var passURLProvider: BaseURLProvider {
        return urlProvider
    }
    
    var shouldShowAlert: Bool {
        return locationHandler.isLocationDenied()
    }
    
    var getSessionName: String {
        return sessionContext.sessionName ?? ""
    }
    
    init(locationHandler: LocationHandler, sessionContext: CreateSessionContext, urlProvider: BaseURLProvider) {
        self.locationHandler = locationHandler
        self.sessionContext = sessionContext
        self.urlProvider = urlProvider
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
