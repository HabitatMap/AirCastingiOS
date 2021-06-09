//
//  AddNameAndTagsView.swift
//  AirCasting
//
//  Created by Anna Olak on 24/02/2021.
//

import CoreLocation
import SwiftUI

struct CreateSessionDetailsView: View {
    let sessionCreator: SessionCreator
    @State var sessionName: String = ""
    @State var sessionTags: String = ""
    @State var isIndoor = true
    @State var isWiFi = false
    @State var isWifiPopupPresented = false
    @State var wifiPassword: String = ""
    @State var wifiSSID: String = ""
    @State private var isConfirmCreatingSessionActive: Bool = false
    @State private var showingAlert = false
    @EnvironmentObject private var sessionContext: CreateSessionContext
    // Location tracker is needed to get wifi SSID (more info CNCopyCurrentNetworkInfo documentation.
    @StateObject private var locationTracker = LocationTracker()

    @Binding var creatingSessionFlowContinues: Bool

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
                        if sessionContext.sessionType == SessionType.fixed {
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
                .onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
    }
}

private extension CreateSessionDetailsView {
    var continueButton: some View {
        Button(action: {
            sessionContext.sessionName = sessionName
            sessionContext.sessionTags = sessionTags
            if sessionContext.sessionType == SessionType.fixed {
                sessionContext.isIndoor = isIndoor
            }
            getAndSaveStartingLocation()
            isConfirmCreatingSessionActive = true
            if !wifiSSID.isEmpty, !wifiPassword.isEmpty {
                sessionContext.wifiSSID = wifiSSID
                sessionContext.wifiPassword = wifiPassword
            } else if isWiFi, wifiSSID.isEmpty, wifiPassword.isEmpty {
                isConfirmCreatingSessionActive = false
                showingAlert = true
            }
        }, label: {
            Text("Continue")
                .frame(maxWidth: .infinity)
        })
            .buttonStyle(BlueButtonStyle())
            .alert(isPresented: $showingAlert, content: {
                Alert(title: Text("Wi-Fi credentials are empty "),
                      message: Text("Do you want to pop up Wi-Fi screen?"),
                      primaryButton: .default(Text("Show Wi-fi screen")) {
                          isWifiPopupPresented = true
                      },
                      secondaryButton: .default(Text("Cancel")))
            })
            .background(Group {
                    NavigationLink(
                        destination: ConfirmCreatingSessionView(sessionCreator: sessionCreator,
                                                                creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                                                sessionName: sessionName),
                        isActive: $isConfirmCreatingSessionActive,
                        label: {
                            EmptyView()
                        }
                    )
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
            .onChange(of: isWiFi) { _ in
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

#if DEBUG
struct AddNameAndTagsView_Previews: PreviewProvider {
    private static var fixedSessionContext: CreateSessionContext = {
        $0.sessionType = .fixed
        return $0
    }(CreateSessionContext())

    static var previews: some View {
        CreateSessionDetailsView(sessionCreator: PreviewSessionCreator(), creatingSessionFlowContinues: .constant(true))
            .environmentObject(CreateSessionContext())

        CreateSessionDetailsView(sessionCreator: PreviewSessionCreator(), creatingSessionFlowContinues: .constant(true))
            .environmentObject(fixedSessionContext)
    }
}
#endif
