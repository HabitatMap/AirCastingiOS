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
        .sheet(isPresented: $isLocationPopupPresented) {
            PlacePicker(service: ChooseLocationPickerService(address: $locationName,
                                                             location: $location))
        }
        .onChange(of: location, perform: { newLocation in
           updateTrackerWithNewLocation(newLocation)
        })
        .padding()
    }

    var mapGoogle: some View {
        _MapView(type: .normal,
                 trackingStyle: .user,
                 userIndicatorStyle: .none,
                 locationTracker: locationTracker)
        .indicateMapLocationChange { newLocation in
            updateTrackerWithNewLocation(.init(latitude: newLocation.coordinate.latitude,
                                               longitude: newLocation.coordinate.longitude))
            location = .init(latitude: newLocation.coordinate.latitude,
                             longitude: newLocation.coordinate.longitude)
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
            guard let location = location else {
                assertionFailure("Location wasn't set")
                return
            }
            sessionContext.startingLocation = location
            isConfirmCreatingSessionActive.toggle()
        }, label: {
            Text(Strings.Commons.continue)
                .font(Fonts.muliBoldHeading1)
        }).buttonStyle(BlueButtonStyle())
    }
    
    var confirmCreatingSessionLink: some View {
        NavigationLink(
            destination: ConfirmCreatingSessionView(creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                                    sessionName: sessionName),
            isActive: $isConfirmCreatingSessionActive,
            label: {
                EmptyView()
            }
        )
    }
    
    private func updateTrackerWithNewLocation(_ loc: CLLocationCoordinate2D?) {
        guard let loc else { return }
        locationTracker.locationSource = loc
        AppLocationTracker.location.value = .init(latitude: loc.latitude,
                                                  longitude: loc.longitude)
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
    }
}
