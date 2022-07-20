//
//  ConfirmCreatingSession.swift
//  AirCasting
//
//  Created by Anna Olak on 22/02/2021.
//

import AirCastingStyling
import CoreLocation
import SwiftUI
import Resolver

struct ConfirmCreatingSessionView: View {
    @State private var isActive: Bool = false
    @State private var error: NSError? {
        didSet {
            isPresentingAlert = error != nil
        }
    }
    @State private var isPresentingAlert: Bool = false
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @InjectedObject private var locationTracker: LocationTracker
    @EnvironmentObject private var tabSelection: TabBarSelection
    @Binding var creatingSessionFlowContinues: Bool

    var sessionName: String
    private var sessionType: String { (sessionContext.sessionType ?? .fixed).description.lowercased() }

    var body: some View {
        LoadingView(isShowing: $isActive) {
            contentViewWithAlert
        }
        .background(Color.aircastingBackgroundWhite.ignoresSafeArea())
    }

    private var contentViewWithAlert: some View {
        contentView.alert(isPresented: $isPresentingAlert) {
            Alert(title: Text(Strings.ConfirmCreatingSessionView.alertTitle),
                  message: Text(error?.localizedDescription ?? Strings.ConfirmCreatingSessionView.alertMessage),
                  dismissButton: .default(Text(Strings.Commons.gotIt), action: { error = nil
            }))
        }
    }

    private var defaultDescriptionText: Text {
        let text = String(format: Strings.ConfirmCreatingSessionView.contentViewText, arguments: [sessionType, sessionName])
        return StringCustomizer.customizeString(text,
                                                using: [sessionType, sessionName],
                                                fontWeight: .bold,
                                                color: .accentColor,
                                                font: Fonts.muliRegularHeading3,
                                                standardFont: Fonts.muliRegularHeading3)
    }

    var dot: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 15, height: 15)
    }

    private var descriptionTextFixed: some View {
        defaultDescriptionText
        + Text((sessionContext.isIndoor!) ? "" : Strings.ConfirmCreatingSessionView.contentViewTextEnd)
    }

    private var descriptionTextMobile: some View {
        defaultDescriptionText
        + Text(Strings.ConfirmCreatingSessionView.contentViewTextEndMobile)
    }

    @ViewBuilder private var contentView: some View {
        if let sessionCreator = setSessioonCreator() {
            VStack(alignment: .leading, spacing: 40) {
                ProgressView(value: 0.95)
                Text(Strings.ConfirmCreatingSessionView.contentViewTitle)
                    .font(Fonts.muliHeavyTitle1)
                    .foregroundColor(.darkBlue)
                VStack(alignment: .leading, spacing: 15) {
                    if sessionContext.sessionType == .fixed {
                        descriptionTextFixed
                    } else if !sessionContext.locationless {
                        descriptionTextMobile
                    } else {
                        defaultDescriptionText
                    }
                }
                .font(Fonts.muliRegularHeading3)
                .foregroundColor(Color.aircastingGray)
                .lineSpacing(9.0)
                ZStack {
                    if sessionContext.sessionType == .mobile {
                        if !sessionContext.locationless {
                            CreatingSessionMapView(isMyLocationEnabled: true)
                        }
                    } else if !(sessionContext.isIndoor ?? false) {
                        CreatingSessionMapView(isMyLocationEnabled: false)
                            .disabled(true)
                        // It needs to be disabled to prevent user interaction (swiping map) because it is only conformation screen
                        dot
                    }
                }
                Button(action: {
                    getAndSaveStartingLocation()
                    isActive = true
                    createSession(sessionCreator: sessionCreator)
                }, label: {
                    Text(Strings.ConfirmCreatingSessionView.startRecording)
                        .font(Fonts.muliBoldHeading1)
                })
                    .buttonStyle(BlueButtonStyle())
            }
            .padding()
        }
    }
}

extension ConfirmCreatingSessionView {

    func createSession(sessionCreator: SessionCreator) {
        sessionCreator.createSession(sessionContext) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.creatingSessionFlowContinues = false
                    if sessionContext.sessionType == .mobile {
                        selectedSection.selectedSection = SelectedSection.mobileActive
                    } else {
                        selectedSection.selectedSection = SelectedSection.following
                    }
                    tabSelection.selection = TabBarSelection.Tab.dashboard

                case .failure(let error):
                    self.error = error as NSError
                    Log.warning("Failed to create session \(error)")
                }
                isActive = false
            }
        }
    }

    func getAndSaveStartingLocation() {
        #if targetEnvironment(simulator)
        let krakowLat = 50.049683
        let krakowLong = 19.944544
        sessionContext.saveCurrentLocation(lat: krakowLat, log: krakowLong)
        return
        #endif
        if sessionContext.sessionType == .fixed || sessionContext.locationless {
            if sessionContext.isIndoor! || sessionContext.locationless {
                locationTracker.googleLocation = [PathPoint.fakePathPoint]
            }
            guard let lat: Double = (locationTracker.googleLocation.last?.location.latitude),
                  let lon: Double = (locationTracker.googleLocation.last?.location.longitude) else { return }
#warning("Do something with exposed googleLocation")
            sessionContext.saveCurrentLocation(lat: lat, log: lon)
        } else {
            guard let lat = (locationTracker.locationManager.location?.coordinate.latitude),
                  let lon = (locationTracker.locationManager.location?.coordinate.longitude) else { return }
            locationTracker.googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: lat, longitude: lon), measurementTime: DateBuilder.getFakeUTCDate())]
            sessionContext.saveCurrentLocation(lat: lat, log: lon)
        }
    }
    func setSessioonCreator() -> SessionCreator? {
        let isWifi: Bool = (sessionContext.wifiSSID != nil && sessionContext.wifiSSID != nil)
        if sessionContext.sessionType == .fixed && isWifi {
            return AirBeamFixedWifiSessionCreator()
        } else if sessionContext.sessionType == .fixed && !isWifi {
            return AirBeamCellularSessionCreator()
        } else if sessionContext.sessionType == .mobile && sessionContext.deviceType == .MIC {
            return MicrophoneSessionCreator()
        } else if sessionContext.sessionType == .mobile {
            return MobilePeripheralSessionCreator()
        } else {
            return nil
            Log.info("Can't set the session creator storage")
        }
    }

}
