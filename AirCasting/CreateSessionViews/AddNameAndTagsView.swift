//
//  AddNameAndTagsView.swift
//  AirCasting
//
//  Created by Anna Olak on 24/02/2021.
//

import SwiftUI

struct AddNameAndTagsView: View {
    @State var sessionName: String = ""
    @State var sessionTags: String = ""
    @State var isIndoor = true
    @State var isWiFi = false
    @State var wifiPassword: String = ""
    @State var wifiSSID: String = ""
    @State private var isConfirmCreatingSessionActive: Bool = false
    @State private var isWifiNameDisplayed: Bool = false
    @EnvironmentObject private var sessionContext: CreateSessionContext

    var body: some View {
        VStack(spacing: 100) {
            VStack(alignment: .leading, spacing: 30) {
                ProgressView(value: 0.75)
                titleLabel
                VStack(spacing: 20) {
                    createTextfield(placeholder: "Session name", binding: $sessionName)
                    createTextfield(placeholder: "Tags", binding: $sessionTags)
                }
                placementPicker
                transmissionTypePicker
            }
            continueButton
        }
        .padding()
    }
    
    var continueButton: some View {
        Button(action: {
            sessionContext.sessionName = sessionName
            sessionContext.sessionTags = sessionTags
            isConfirmCreatingSessionActive = true
        }, label: {
            Text("Continue")
                .frame(maxWidth: .infinity)
        })
        .buttonStyle(BlueButtonStyle())
        .background( Group {
            NavigationLink(
                destination: ConfirmCreatingSessionView(sessionName: sessionName),
                isActive: $isConfirmCreatingSessionActive,
                label: {
                    EmptyView()
                })
        })
    }
    
    var titleLabel: some View {
        Text("New session details")
            .font(Font.moderate(size: 24, weight: .bold))
            .foregroundColor(.darkBlue)
    }
    
    var placementPicker: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Where will you place your AirBeam?")
                .font(Font.moderate(size: 16, weight: .bold))
                .foregroundColor(.aircastingDarkGray)
            Picker(selection: $isIndoor,
                   label: Text("")) {
                Text("Indoor").tag(true)
                Text("Outdoor").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    var transmissionTypePicker: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Data transmission:")
                .font(Font.moderate(size: 16, weight: .bold))
                .foregroundColor(.aircastingDarkGray)
            Picker(selection: $isWiFi,
                   label: Text("")) {
                Text("Cellular").tag(false)
                Text("Wi-Fi").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .sheet(isPresented: $isWiFi) {
            wifiPopup
        }
    }

    var wifiPopup: some View {
        VStack(alignment: .leading, spacing: 30){
            if isWifiNameDisplayed {
                Text("Provide name and password for the Wi-Fi network")
                    .font(Font.muli(size: 18, weight: .heavy))
                    .foregroundColor(.darkBlue)
                
                createTextfield(placeholder: "Wi-Fi name", binding: $wifiSSID)
            } else {
                Text("Provide password for \(wifiSSID) network")
                    .font(Font.muli(size: 18, weight: .heavy))
                    .foregroundColor(.darkBlue)
            }
            createTextfield(placeholder: "Password", binding: $wifiPassword)

            Button("I'd like to connect with different Wi-Fi network.") {
                isWifiNameDisplayed = true
            }
            Button("Connect") {
                if wifiSSID != "" {
                    sessionContext.wifiSSID = wifiSSID
                }
                sessionContext.wifiPassword = wifiPassword
                
                //dismiss popup
            } .buttonStyle(BlueButtonStyle())
            
            Button("Cancel") {
                // dismiss popup
            }
            Spacer()
        }
        .padding()
    }
}

struct AddNameAndTagsView_Previews: PreviewProvider {
    static var previews: some View {
        AddNameAndTagsView()
    }
}
