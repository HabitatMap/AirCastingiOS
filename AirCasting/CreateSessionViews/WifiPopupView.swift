//
//  WifiPopupView.swift
//  AirCasting
//
//  Created by Lunar on 15/03/2021.
//

import AirCastingStyling
import SwiftUI
import SystemConfiguration.CaptiveNetwork

struct WifiPopupView: View {
    @State private var isSSIDTextfieldDisplayed: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    @Binding var wifiPassword: String
    @Binding var wifiSSID: String
    @State var wifiSSIDWasEmptyAtStart: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            if isSSIDTextfieldDisplayed {
                providePasswordTitle
                createTextfield(placeholder: Strings.WifiPopupView.wifiPlaceholder, binding: $wifiSSID)
            } else {
                provideNameAndPasswordTitle
                    .font(Font.muli(size: 18, weight: .heavy))
                    .foregroundColor(.darkBlue)
            }
            createTextfield(placeholder: Strings.WifiPopupView.passwordPlaceholder, binding: $wifiPassword).onTapGesture {
                isSSIDTextfieldDisplayed = false
            }
            if !isSSIDTextfieldDisplayed {
                connectToDifferentWifi
            }
            VStack(spacing: 10) {
                Button(Strings.WifiPopupView.connectButton) {
                    presentationMode.wrappedValue.dismiss()
                }.buttonStyle(BlueButtonStyle())
                
                Button(Strings.WifiPopupView.cancelButton) {
                    wifiPassword = ""
                    wifiSSID = ""
                    presentationMode.wrappedValue.dismiss()
                }.buttonStyle(BlueTextButtonStyle())
            }
            Spacer()
        }
        .padding()
        .onAppear {
            if let ssid = getWiFiSsid() {
                wifiSSID = ssid
            }
            if wifiSSID.isEmpty {
                isSSIDTextfieldDisplayed = true
            }
        }
    }
    
    var providePasswordTitle: some View {
        Text(Strings.WifiPopupView.passwordTitle)
            .font(Font.muli(size: 18, weight: .heavy))
            .foregroundColor(.darkBlue)
    }
    
    var provideNameAndPasswordTitle: some View {
        Text(Strings.WifiPopupView.nameAndPasswordTitle_1) +
            Text(wifiSSID) +
            Text(Strings.WifiPopupView.nameAndPasswordTitle_2)
    }
    
    var connectToDifferentWifi: some View {
        Button(Strings.WifiPopupView.differentNetwork) {
            isSSIDTextfieldDisplayed = true
        }
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
