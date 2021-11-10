// Created by Lunar on 10/11/2021.
//
import Foundation
import SystemConfiguration.CaptiveNetwork
import SwiftUI

class CreateSessionDetailsViewModel: ObservableObject {
    
    @Published var sessionName: String = ""
    @Published var sessionTags: String = ""
    @Published var isIndoor = true
    @Published var isWiFi = true
    @Published var wifiPassword: String = ""
    @Published var wifiSSID: String = ""
    @Published var isConfirmCreatingSessionActive: Bool = false
    @Published var isLocationSessionDetailsActive: Bool = false
    @Published var showingAlert = false
    @Published var isSSIDTextfieldDisplayed: Bool = false
    
    let baseURL: BaseURLProvider
    
    init(baseURL: BaseURLProvider) {
        self.baseURL = baseURL
    }
    
    func onScreenEnter() {
        if let ssid = getWiFiSsid() { wifiSSID = ssid }
        isSSIDTextfieldDisplayed = wifiSSID.isEmpty
    }
    
    func onContinueClick(sessionContext: CreateSessionContext) -> CreateSessionContext {
        sessionContext.sessionName = sessionName
        sessionContext.sessionTags = sessionTags
        
        if sessionContext.sessionType == SessionType.fixed {
            sessionContext.isIndoor = isIndoor
            if isWiFi, !(areCredentialsEmpty()) {
                sessionContext.wifiSSID = wifiSSID
                sessionContext.wifiPassword = wifiPassword
            } else if isWiFi, areCredentialsEmpty() {
                isConfirmCreatingSessionActive = false
                showingAlert = true
                return sessionContext
            } else if !isWiFi {
                // to be able to check if session is cellular
                sessionContext.wifiSSID = nil
                sessionContext.wifiPassword = nil
            }
            isConfirmCreatingSessionActive = isIndoor
            isLocationSessionDetailsActive = isIndoor
        } else {
            sessionContext.isIndoor = false
            isConfirmCreatingSessionActive = true
        }
        return sessionContext
    }
    
    func areCredentialsEmpty() -> Bool {
        wifiSSID.isEmpty && wifiPassword.isEmpty
    }
    
    func connectToOtherNetworkClick() {
        isSSIDTextfieldDisplayed = true
    }
    
    func showCompleteCredentials() -> Bool {
        isWiFi && isSSIDTextfieldDisplayed
    }
    
    func getWiFiSsid() -> String? {
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    break
                }
            }
        }
        return ssid
    }
}
