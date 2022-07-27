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
    @State var placePickerIsUpdating: Bool = false
    @State var isLocationPopupPresented = false
    @Binding var creatingSessionFlowContinues: Bool
    var sessionName: String
    
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
        .onChange(of: isLocationPopupPresented, perform: { present in
            // The reason for this is to prevent map from multiple times refreshing after first map update
            placePickerIsUpdating = !present
        })
        .padding()
    }

    var mapGoogle: some View {
        GoogleMapView(pathPoints: [],
                      placePickerIsUpdating: $placePickerIsUpdating,
                      isUserInteracting: Binding.constant(true),
                      mapNotes: .constant([]),
                      isMapOnPickerScreen: true, placePickerLocation: $location)
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
