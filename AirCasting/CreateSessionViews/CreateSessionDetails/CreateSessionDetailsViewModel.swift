// Created by Lunar on 10/11/2021.
//
import Foundation
import SystemConfiguration.CaptiveNetwork
import Resolver

class CreateSessionDetailsViewModel: ObservableObject {
    
    @Published var sessionName: String = ""
    @Published var sessionTags: String = ""
    @Published var isIndoor = true
    @Published var isWiFi = true
    @Published var wifiPassword: String = ""
    @Published var wifiSSID: String = ""
    @Published var isConfirmCreatingSessionActive: Bool = false
    @Published var isLocationSessionDetailsActive: Bool = false
    @Published var isLocationScreenNedeed: Bool = false
    @Published var showAlertAboutEmptyCredentials = false
    @Published var isSSIDTextfieldDisplayed: Bool = false
    @Published var showErrorIndicator: Bool = false
    @Published var showWifiPasswordField = true
    var shouldShowError: Bool { sessionName.isEmpty && showErrorIndicator }
    @Injected private var locationAuthorization: LocationAuthorization
    
    func onScreenEnter() {
        if let ssid = getWiFiSsid() {
            wifiSSID = ssid
            if let data = KeychainManager.get(service: "wifi", account: ssid), let password = String(data: data, encoding: .utf8) {
                wifiPassword = password
                showWifiPasswordField = false
            }
        }
        isSSIDTextfieldDisplayed = wifiSSID.isEmpty
    }
    
    func onContinueClick(sessionContext: CreateSessionContext) -> CreateSessionContext {
        saveWifiPassword()
        // sessionContext is needed becouse it is being modified in the session creation proccess
        // by 'modified' I mean - the data it ovverriden by the proper one (get from user) on every step
        guard !sessionName.isEmpty else { showErrorIndicator = true; return sessionContext }
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
    
    private func saveWifiPassword() {
        guard !wifiPassword.isEmpty else { return }
        guard let passwordData = wifiPassword.data(using: .utf8) else { return }
        try? KeychainManager.save(service: "wifi", account: wifiSSID, password: passwordData)
    }
    
    private func checkIfWiFi(sessionContext: CreateSessionContext) -> CreateSessionContext {
        if isWiFi, !(areCredentialsEmpty()) {
            sessionContext.wifiSSID = wifiSSID
            sessionContext.wifiPassword = wifiPassword
        } else if areCredentialsEmpty() {
            showAlertAboutEmptyCredentials = true
        } else if !isWiFi {
            // to be able to check if session is cellular
            sessionContext.wifiSSID = nil
            sessionContext.wifiPassword = nil
        }
        return sessionContext
    }
    
    private func compareIsIndoor(sessionContext: CreateSessionContext) -> CreateSessionContext {
        sessionContext.isIndoor = isIndoor
        guard locationAuthorization.locationState == .denied && !isIndoor else {
            isLocationSessionDetailsActive = !isIndoor
            isConfirmCreatingSessionActive = isIndoor
            return sessionContext
        }
        isLocationScreenNedeed = true
        return sessionContext
    }
    
    func areCredentialsEmpty() -> Bool {
        isWiFi && wifiSSID.isEmpty && wifiPassword.isEmpty
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
