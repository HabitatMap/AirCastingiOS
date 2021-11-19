// Created by Lunar on 10/11/2021.
//
import Foundation
import SystemConfiguration.CaptiveNetwork

class CreateSessionDetailsViewModel: ObservableObject {
    
    @Published var sessionName: String = ""
    @Published var sessionTags: String = ""
    @Published var isIndoor = true
    @Published var isWiFi = true
    @Published var wifiPassword: String = ""
    @Published var wifiSSID: String = ""
    @Published var isConfirmCreatingSessionActive: Bool = false
    @Published var isLocationSessionDetailsActive: Bool = false
    @Published var showAlertAboutEmptyCredentials = false
    @Published var isSSIDTextfieldDisplayed: Bool = false
    
    let baseURL: BaseURLProvider
    // It cannot be private as long as it is going to be passed
    // by every view which is included in session creation process
    
    init(baseURL: BaseURLProvider) {
        self.baseURL = baseURL
    }
    
    func onScreenEnter() {
        if let ssid = getWiFiSsid() { wifiSSID = ssid }
        isSSIDTextfieldDisplayed = wifiSSID.isEmpty
    }
    
    func onContinueClick(sessionContext: CreateSessionContext) -> CreateSessionContext {
        // sessionContext is needed becouse it is being modified in the session creation proccess
        // by 'modified' I mean - the data it ovverriden by the proper one (get from user) on every step
        sessionContext.sessionName = sessionName
        sessionContext.sessionTags = sessionTags
        
        guard sessionContext.sessionType == .fixed else {
            sessionContext.isIndoor = false
            isConfirmCreatingSessionActive = true
            return sessionContext
        }
        sessionContext.ovverride(sessionContext: checkIfWiFi(sessionContext: sessionContext))
        sessionContext.ovverride(sessionContext: compareIsIndoor(sessionContext: sessionContext))
        return sessionContext
    }
    
    func checkIfWiFi(sessionContext: CreateSessionContext) -> CreateSessionContext {
        if isWiFi, !(areCredentialsEmpty()) {
            sessionContext.wifiSSID = wifiSSID
            sessionContext.wifiPassword = wifiPassword
        } else if isWiFi, areCredentialsEmpty() {
            isConfirmCreatingSessionActive = false
            showAlertAboutEmptyCredentials = true
        } else if !isWiFi {
            // to be able to check if session is cellular
            sessionContext.wifiSSID = nil
            sessionContext.wifiPassword = nil
        }
        return sessionContext
    }
    
    func compareIsIndoor(sessionContext: CreateSessionContext) -> CreateSessionContext {
        sessionContext.isIndoor = isIndoor
        isConfirmCreatingSessionActive = isIndoor
        isLocationSessionDetailsActive = isIndoor
        return sessionContext
    }
    
    func areCredentialsEmpty() -> Bool {
        wifiSSID.isEmpty && wifiPassword.isEmpty
    }
    
    func connectToOtherNetworkClick() {
        isSSIDTextfieldDisplayed = true
    }
    
    func shouldShowCompleteCredentials() -> Bool {
        isWiFi && isSSIDTextfieldDisplayed
    }
    
    private func getWiFiSsid() -> String? {
        var ssid: String?
        guard let interfaces = CNCopySupportedInterfaces() as NSArray? else { return "" }
        for interface in interfaces {
            if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                break
            }
        }
        return ssid
    }
}
