// Created by Lunar on 27/01/2022.
//
import Foundation
import Resolver

class TurnOnLocationFixedViewModel: ObservableObject {
    
    @Published var isLocationSessionDetailsActive: Bool = false
    @Published var alert: AlertInfo?
    
    private let sessionContext: CreateSessionContext
    @Injected private var locationAuthorization: LocationAuthorization
    @Injected private var urlProvider: URLProvider
    
    var shouldShowAlert: Bool {
        locationAuthorization.locationState == .denied
    }
    
    var getSessionName: String {
        sessionContext.sessionName ?? ""
    }
    
    init(sessionContext: CreateSessionContext) {
        self.sessionContext = sessionContext
    }
    
    func requestLocationAuthorisation() {
        locationAuthorization.requestAuthorization()
    }
    
    func onContinueButtonClick() {
        isLocationSessionDetailsActive = true
    }
    
    func onTurnOnButtonClicked() {
        switch shouldShowAlert {
        case true:
            alert = InAppAlerts.locationAlert()
        case false:
            isLocationSessionDetailsActive = true
        }
    }
}
