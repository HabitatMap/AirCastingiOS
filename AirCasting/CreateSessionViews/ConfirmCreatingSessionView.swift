//
//  ConfirmCreatingSession.swift
//  AirCasting
//
//  Created by Anna Olak on 22/02/2021.
//

import AirCastingStyling
import CoreLocation
import SwiftUI

struct ConfirmCreatingSessionView: View {
    @State private var isActive: Bool = false
    @State private var error: NSError? {
        didSet {
            isPresentingAlert = error != nil
        }
    }

    @State private var isPresentingAlert: Bool = false
    @State private var didStartRecordingSession = false
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @EnvironmentObject private var locationTracker: LocationTracker
    @EnvironmentObject private var tabSelection: TabBarSelection
    @Binding var creatingSessionFlowContinues: Bool
    let sessionCreator: SessionCreator
    var sessionName: String
    private var sessionType: String { (sessionContext.sessionType ?? .fixed).description.lowercased() }

    var body: some View {
        LoadingView(isShowing: $isActive) {
            contentViewWithAlert
        }
    }

    private var contentViewWithAlert: some View {
        contentView.alert(isPresented: $isPresentingAlert) {
            Alert(title: Text(Strings.ConfirmCreatingSessionView.alertTitle),
                  message: Text(error?.localizedDescription ?? Strings.ConfirmCreatingSessionView.alertMessage),
                  dismissButton: .default(Text(Strings.ConfirmCreatingSessionView.alertOK), action: { error = nil
                  }))
        }
    }

    private var defaultDescriptionText: Text {
        Text(Strings.ConfirmCreatingSessionView.contentViewText_1)
            + Text(sessionType)
            .foregroundColor(.accentColor)
            + Text(Strings.ConfirmCreatingSessionView.contentViewText_2)
            + Text(sessionName)
            .foregroundColor(.accentColor)
            + Text(Strings.ConfirmCreatingSessionView.contentViewText_3)
    }

    var dot: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 15, height: 15)
    }

    private var descriptionTextFixed: some View {
        defaultDescriptionText
            + Text((sessionContext.isIndoor!) ? "" : Strings.ConfirmCreatingSessionView.contentViewText_4)
    }

    private var descriptionTextMobile: some View {
        defaultDescriptionText
            + Text(Strings.ConfirmCreatingSessionView.contentViewText_4Mobile)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 40) {
            ProgressView(value: 0.95)
            Text(Strings.ConfirmCreatingSessionView.contentViewTitle)
                .font(Font.moderate(size: 24, weight: .bold))
                .foregroundColor(.darkBlue)
            VStack(alignment: .leading, spacing: 15) {
                if sessionContext.sessionType == .fixed {
                    descriptionTextFixed
                } else {
                    descriptionTextMobile
                }
            }
            .font(Font.muli(size: 16))
            .foregroundColor(Color.aircastingGray)
            .lineSpacing(9.0)
            ZStack {
                if sessionContext.sessionType == .mobile {
                    GoogleMapView(pathPoints: [], isMyLocationEnabled: true)
                } else if !(sessionContext.isIndoor ?? false) {
                    GoogleMapView(pathPoints: [])
                        .disabled(true)
                    // It needs to be disabled to prevent user interaction (swiping map) because it is only conformation screen
                    dot
                }
            }
            Button(action: {
                getAndSaveStartingLocation()
                isActive = true
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
            }, label: {
                Text(Strings.ConfirmCreatingSessionView.startRecording)
                    .bold()
            })
                .buttonStyle(BlueButtonStyle())
        }
        .padding()
    }

    func getAndSaveStartingLocation() {
        if sessionContext.sessionType == .fixed {
            if sessionContext.isIndoor! {
                locationTracker.googleLocation = [PathPoint.fakePathPoint]
            } else {
                guard let lat: Double = (locationTracker.googleLocation.last?.location.latitude),
                      let lon: Double = (locationTracker.googleLocation.last?.location.longitude) else { return }
                #warning("Do something with exposed googleLocation")
                sessionContext.obtainCurrentLocation(lat: lat, log: lon)
            }
        } else {
            guard let lat = (locationTracker.locationManager.location?.coordinate.latitude),
                  let lon = (locationTracker.locationManager.location?.coordinate.longitude) else { return }
            locationTracker.googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: lat, longitude: lon), measurementTime: Date(), measurement: 20.0)]
            #warning("Do something with hard coded measurement")
            sessionContext.obtainCurrentLocation(lat: lat, log: lon)
        }
    }
}

#if DEBUG
struct ConfirmCreatingSession_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmCreatingSessionView(creatingSessionFlowContinues: .constant(true),
                                   sessionCreator: PreviewSessionCreator(),
                                   sessionName: "Ania's microphone session")
            .environmentObject(CreateSessionContext())
            .previewDevice(PreviewDevice(rawValue: "iPhone 12 mini"))
    }
}
#endif
