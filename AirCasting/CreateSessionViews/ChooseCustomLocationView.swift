// Created by Lunar on 11/08/2021.
//

import AirCastingStyling
import SwiftUI
import CoreLocation
import Resolver

struct ChooseCustomLocationView: View {
    @State private var isConfirmCreatingSessionActive: Bool = false
    @State private var locationName = ""
    @State private var location: CLLocationCoordinate2D?
    @State var isLocationPopupPresented = false
    @Binding var creatingSessionFlowContinues: Bool
    @StateObject private var locationTracker = BindableLocationTracker()
    var sessionName: String
    @State private var locationChangedProgramatically: Bool = false
    @Injected private var AppLocationTracker: LocationTracker
    
    @EnvironmentObject private var sessionContext: CreateSessionContext

    var body: some View {
        VStack(spacing: 40) {
            ProgressView(value: 0.85)
            titleLabel
            createTextfield(placeholder: Strings.ChooseCustomLocationView.sessionLocation,
                            binding: $locationName)
                .font(Fonts.moderateRegularHeading2)
                .disabled(true)
                .onTapGesture {
                    isLocationPopupPresented.toggle()
                }
            ZStack {
                mapGoogle
                dot
            }
            confirmButton
        }
        .background(confirmCreatingSessionLink)
        .sheet(isPresented: $isLocationPopupPresented, onDismiss: {
            guard let newLocation = location else { return }
            
            locationChangedProgramatically = true
            locationTracker.ovverridenLocation = newLocation
        }, content: {
            PlacePicker(service: ChooseLocationPickerService(address: $locationName,
                                                             location: $location))
        })
        .onDisappear {
            // On locationTracker init, AppLocationTracker starts monitoring
            // here we finish the process as its deinit is not working
            AppLocationTracker.stop()
        }
        .padding()
    }

    var mapGoogle: some View {
        _MapView(type: .normal,
                 trackingStyle: .user,
                 userIndicatorStyle: .none,
                 locationTracker: locationTracker,
                 stickHardToTheUser: true)
        .indicateMapLocationChange { newLocation in
            if !locationChangedProgramatically {
                locationChangedProgramatically = false
                location = .init(latitude: newLocation.coordinate.latitude,
                                 longitude: newLocation.coordinate.longitude)
            }
        }
        .onMyLocationButtonTapped {
            locationTracker.ovverridenLocation = nil
        }
    }

    var dot: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 15, height: 15)
    }

    var titleLabel: some View {
        Text(Strings.ChooseCustomLocationView.titleLabel)
            .font(Fonts.muliHeavyTitle2)
            .foregroundColor(.darkBlue)
    }
    
    var confirmButton: some View {
        Button(action: {
            // `location` is only populated by `indicateMapLocationChange`, which
            // fires when the user drags the map. If the user accepts the default
            // (map snapped to GPS via `stickHardToTheUser`), `location` stays nil
            // and the previous `assertionFailure("Location wasn't set")` crashed
            // the outdoor fixed-session wizard. Fall back to the last known GPS
            // coordinate the `BindableLocationTracker` already exposes — that's
            // the same point the map is centered on.
            let resolved = location ?? locationTracker.getLastKnownLocation().map {
                CLLocationCoordinate2D(latitude: $0.coordinate.latitude,
                                       longitude: $0.coordinate.longitude)
            }
            guard let confirmed = resolved else {
                Log.error("ChooseCustomLocationView: no GPS and no map-picked location available")
                return
            }
            sessionContext.startingLocation = confirmed
            isConfirmCreatingSessionActive.toggle()
        }, label: {
            Text(Strings.Commons.continue)
                .font(Fonts.muliBoldHeading1)
        }).buttonStyle(BlueButtonStyle())
    }
    
    var confirmCreatingSessionLink: some View {
        NavigationLink(
            destination: ConfirmCreatingSessionView(creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                                    sessionName: sessionName,
                                                    initialLocation: location.map({
                                                        .init(latitude: $0.latitude,
                                                              longitude: $0.longitude)
                                                    })),
            isActive: $isConfirmCreatingSessionActive,
            label: {
                EmptyView()
            }
        )
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
    }
}
