//
//  AddNameAndTagsView.swift
//  AirCasting
//
//  Created by Anna Olak on 24/02/2021.
//

import SwiftUI
import CoreLocation

struct AddNameAndTagsView: View {
    @State var sessionName: String = ""
    @State var sessionTags: String = ""
    @State var isIndoor = true
    @State var isWiFi = false
    @State var isWifiPopupPresented = false
    @State var wifiPassword: String = ""
    @State var wifiSSID: String = ""
    @State private var isConfirmCreatingSessionActive: Bool = false
    @Environment(\.presentationMode) var presentationMode

    // Location tracker is needed to get wifi SSID (more info CNCopyCurrentNetworkInfo documentation.
    @StateObject private var locationTracker = LocationTracker()
    
    @Binding var dashboardIsActive : Bool
    @StateObject var sessionContext: CreateSessionContext
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack {
                    VStack(alignment: .leading, spacing: 30) {
                        ProgressView(value: 0.75)
                        titleLabel
                        VStack(spacing: 20) {
                            createTextfield(placeholder: "Session name", binding: $sessionName)
                            createTextfield(placeholder: "Tags", binding: $sessionTags)
                        }
                        if sessionContext.sessionType == SessionType.FIXED {
                            placementPicker
                            transmissionTypePicker
                        }
                    }
                    Spacer()
                    continueButton
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
            }
        }
                .simultaneousGesture(
        
            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged({ (_) in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                })
        )
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: BackButton(presentationMode: presentationMode))
    }
    
    var continueButton: some View {
        Button(action: {
            sessionContext.sessionName = sessionName
            sessionContext.sessionTags = sessionTags
            if sessionContext.sessionType == SessionType.FIXED {
                sessionContext.isIndoor = isIndoor
            }
            getAndSaveStartingLocation()
            isConfirmCreatingSessionActive = true
            if wifiSSID != "" && wifiPassword != "" {
                sessionContext.wifiSSID = wifiSSID
                sessionContext.wifiPassword = wifiPassword
            }
        }, label: {
            Text("Continue")
                .frame(maxWidth: .infinity)
        })
        .buttonStyle(BlueButtonStyle())
        .background( Group {
            NavigationLink(
                destination: ConfirmCreatingSessionView(dashboardIsActive: $dashboardIsActive, sessionContext: sessionContext, sessionName: sessionName),
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
            .onChange(of: isWiFi) { (_) in
                isWifiPopupPresented = isWiFi
            }
        }
        .sheet(isPresented: $isWifiPopupPresented) {
            WifiPopupView(wifiPassword: $wifiPassword, wifiSSID: $wifiSSID)
        }
    }
    
    func getAndSaveStartingLocation() {
        let fakeLocation = CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0)
        if isIndoor {
            sessionContext.startingLocation = fakeLocation
        } else {
            sessionContext.obtainCurrentLocation()
        }
    }

}

struct AddNameAndTagsView_Previews: PreviewProvider {
    static var previews: some View {
        AddNameAndTagsView(dashboardIsActive: .constant(true), sessionContext: CreateSessionContext(createSessionService: CreateSessionAPIService(authorisationService: UserAuthenticationSession()), managedObjectContext: PersistenceController.shared.container.viewContext))
    }
}
