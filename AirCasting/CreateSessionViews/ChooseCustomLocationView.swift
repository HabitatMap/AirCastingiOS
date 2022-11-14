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
    @Injected private var ApplocationTracker: LocationTracker
    
    @EnvironmentObject private var sessionContext: CreateSessionContext

    var body: some View {
        VStack(spacing: 40) {
            ProgressView(value: 0.85)
            titleLabel
            createTextfield(placeholder: Strings.ChooseCustomLocationView.sessionLocation, binding: $locationName)
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
            PlacePicker(service: ChooseLocationPickerService(address: $locationName, location: $location))
        }
        .onChange(of: location, perform: { newLocation in
            guard let newLocation else { return }
            locationTracker.locationSource = newLocation
            ApplocationTracker.location.value = .init(latitude: newLocation.latitude, longitude: newLocation.longitude)
        })
        .padding()
    }

    var mapGoogle: some View {
        // TODO: Remember to revert this view from being shown in the mobile session wizard! (createSesssionLink in CreateSessionDetailsView.swift)
        _MapView(type: .normal,
                 trackingStyle: .user,
                 userIndicatorStyle: .none,
                 userTracker: locationTracker)
//        GoogleMapView(pathPoints: [],
//                      placePickerIsUpdating: $placePickerIsUpdating,
//                      isUserInteracting: Binding.constant(true),
//                      mapNotes: .constant([]),
//                      isMapOnPickerScreen: true,
//                      placePickerLocation: $location)
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
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
    }
}
