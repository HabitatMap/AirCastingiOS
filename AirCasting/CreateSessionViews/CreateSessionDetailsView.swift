//
//  AddNameAndTagsView.swift
//  AirCasting
//
//  Created by Anna Olak on 24/02/2021.
//

import AirCastingStyling
import CoreLocation
import SwiftUI

struct CreateSessionDetailsView: View {
    let sessionCreator: SessionCreator
    @State var sessionName: String = ""
    @State var sessionTags: String = ""
    @State var isIndoor = true
    @State var isWiFi = false
    @State var adress = ""
    @State var isWifiPopupPresented = false
    @State var isLocationPopupPresented = false
    @State var wifiPassword: String = ""
    @State var wifiSSID: String = ""
    @State private var isConfirmCreatingSessionActive: Bool = false
    @State private var isLocationSessionDetailsActive: Bool = false
    @State private var showingAlert = false
    @EnvironmentObject private var sessionContext: CreateSessionContext
    // Location tracker is needed to get wifi SSID (more info CNCopyCurrentNetworkInfo documentation.
    let locationTracker: LocationTracker

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
            }.background(Group {
                NavigationLink(
                    destination: ChooseCustomLocationView(sessionCreator: sessionCreator, tracker: locationTracker, creatingSessionFlowContinues: $creatingSessionFlowContinues, sessionName: $sessionName),
                    isActive: $isLocationSessionDetailsActive,
                    label: {
                        EmptyView()
                    }
                )
                NavigationLink("", destination: EmptyView())
                NavigationLink(
                    destination: ConfirmCreatingSessionView(sessionCreator: sessionCreator,
                                                            locationTracker: locationTracker,
                                                            creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                                            sessionName: sessionName),
                    isActive: $isConfirmCreatingSessionActive,
                    label: {
                        EmptyView()
                    }
                )

            })
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
            } else {
                sessionContext.isIndoor = false
            }
            getAndSaveStartingLocation()
            isConfirmCreatingSessionActive = isIndoor
            isLocationSessionDetailsActive = !isIndoor
            if !wifiSSID.isEmpty, !wifiPassword.isEmpty {
                sessionContext.wifiSSID = wifiSSID
                sessionContext.wifiPassword = wifiPassword
            } else if isWiFi, wifiSSID.isEmpty, wifiPassword.isEmpty {
                isConfirmCreatingSessionActive = false
                showingAlert = true
            }
        }, label: {
            Text(Strings.CreateSessionDetailsView.continueButton)
                .frame(maxWidth: .infinity)
        })
            .buttonStyle(BlueButtonStyle())
            .alert(isPresented: $showingAlert, content: {
                Alert(title: Text(Strings.CreateSessionDetailsView.wifiAlertTitle),
                      message: Text(Strings.CreateSessionDetailsView.wifiAlertMessage),
                      primaryButton: .default(Text(Strings.CreateSessionDetailsView.primaryWifiButton)) {
                          isWifiPopupPresented = true
                      },
                      secondaryButton: .default(Text(Strings.CreateSessionDetailsView.cancelButton)))
            })
    }

    var titleLabel: some View {
        Text(Strings.CreateSessionDetailsView.title)
            .font(Font.moderate(size: 24, weight: .bold))
            .foregroundColor(.darkBlue)
    }

    var placementPicker: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(Strings.CreateSessionDetailsView.placementPicker_1)
                .font(Font.moderate(size: 16, weight: .bold))
                .foregroundColor(.aircastingDarkGray)
            Picker(selection: $isIndoor,
                   label: Text("")) {
                Text(Strings.CreateSessionDetailsView.placementPicker_2).tag(true)
                Text(Strings.CreateSessionDetailsView.placementPicker_3).tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    var transmissionTypePicker: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(Strings.CreateSessionDetailsView.transmissionPicker)
                .font(Font.moderate(size: 16, weight: .bold))
                .foregroundColor(.aircastingDarkGray)
            Picker(selection: $isWiFi,
                   label: Text("")) {
                Text(Strings.CreateSessionDetailsView.cellularText).tag(false)
                Text(Strings.CreateSessionDetailsView.wifiText).tag(true)
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
        if sessionContext.sessionType == .fixed {
            if isIndoor {
                sessionContext.startingLocation = fakeLocation
                locationTracker.googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0), measurementTime: Date(), measurement: 20.0)]
                // measurement: 20.0 was designed just to be 'something'. Is should be handle somehow, but for now we are leaving this like it is.
            } else {
                guard let lat = (locationTracker.locationManager.location?.coordinate.latitude),
                      let lon = (locationTracker.locationManager.location?.coordinate.longitude) else { return }
                locationTracker.googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: lat, longitude: lon), measurementTime: Date(), measurement: 20.0)]
                #warning("Do something with exposed googleLocation")
                // measurement: 20.0 was designed just to be 'something'. Is should be handle somehow, but for now we are leaving this like it is.
                sessionContext.obtainCurrentLocation(lat: lat, log: lon)
            }
        } else {
            guard let lat = (locationTracker.locationManager.location?.coordinate.latitude),
                  let lon = (locationTracker.locationManager.location?.coordinate.longitude) else { return }
            locationTracker.googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: lat, longitude: lon), measurementTime: Date(), measurement: 20.0)]
            // measurement: 20.0 was designed just to be 'something'. Is should be handle somehow, but for now we are leaving this like it is.
            sessionContext.obtainCurrentLocation(lat: lat, log: lon)
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
        CreateSessionDetailsView(sessionCreator: PreviewSessionCreator(), locationTracker: DummyLocationTrakcer(), creatingSessionFlowContinues: .constant(true))
            .environmentObject(CreateSessionContext())

        CreateSessionDetailsView(sessionCreator: PreviewSessionCreator(), locationTracker: DummyLocationTrakcer(), creatingSessionFlowContinues: .constant(true))
            .environmentObject(fixedSessionContext)
    }
}
#endif
