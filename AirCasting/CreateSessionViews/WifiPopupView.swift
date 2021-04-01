//
//  WifiPopupView.swift
//  AirCasting
//
//  Created by Lunar on 15/03/2021.
//

import SwiftUI
import Foundation
import SystemConfiguration.CaptiveNetwork


struct WifiPopupView: View {
    
    @State private var isWifiNameDisplayed: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    @Binding var wifiPassword: String
    @Binding var wifiSSID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 30){
            if isWifiNameDisplayed {
                providePasswordTitle
                createTextfield(placeholder: "Wi-Fi name", binding: $wifiSSID)
                createTextfield(placeholder: "Password", binding: $wifiPassword)
            } else {
                provideNameAndPasswordTitle
                createTextfield(placeholder: "Password", binding: $wifiPassword)
                connectToDifferentWifi
            }
            VStack(spacing: 10) {
                Button("Connect") {
                    presentationMode.wrappedValue.dismiss()
                } .buttonStyle(BlueButtonStyle())
                
                Button("Cancel") {
                    wifiPassword = ""
                    wifiSSID = ""
                    presentationMode.wrappedValue.dismiss()
                }.buttonStyle(BlueTextButtonStyle())
            }
            Spacer()
        }
        .padding()
        .onAppear {
            wifiSSID = getWiFiSsid() ?? ""
        }
    }
    
    var providePasswordTitle: some View {
        Text("Provide name and password for the Wi-Fi network")
            .font(Font.muli(size: 18, weight: .heavy))
            .foregroundColor(.darkBlue)
    }
    
    var provideNameAndPasswordTitle: some View {
        Text("Provide password for \(wifiSSID ?? "your") network")
            .font(Font.muli(size: 18, weight: .heavy))
            .foregroundColor(.darkBlue)
    }
    
    var connectToDifferentWifi: some View {
        Button("I'd like to connect with a different Wi-Fi network.") {
            isWifiNameDisplayed = true
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
