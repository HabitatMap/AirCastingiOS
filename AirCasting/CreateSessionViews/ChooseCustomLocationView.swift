// Created by Lunar on 11/08/2021.
//

import AirCastingStyling
import SwiftUI

struct ChooseCustomLocationView: View {
    @State private var isConfirmCreatingSessionActive: Bool = false
    @State private var location = ""
    @State var placePickerPushUpdate: Bool = false
    @State var isLocationPopupfoPresented = false
    @Binding var creatingSessionFlowContinues: Bool
    var sessionName: String
    let not = (!)

    var body: some View {
        VStack(spacing: 40) {
            ProgressView(value: 0.85)
            titleLabel
            createTextfield(placeholder: Strings.ChooseCustomLocationView.sessionLocation, binding: $location)
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
            PlacePicker(service: ChooseLocationPickerService(address: $location))
        }
        .onChange(of: isLocationPopupPresented, perform: { present in
            // The reason for this is to prevent map from multiple times refreshing after first map update
            not(present) ? (placePickerPushUpdate = true) : (placePickerPushUpdate = false)
        })
        .padding()
    }

    var mapGoogle: some View {
        GoogleMapView(pathPoints: [],
                      placePickerDismissed: $placePickerPushUpdate,
                      isUserInteracting: Binding.constant(true),
                      mapNotes: .constant([]))
    }

    var dot: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 15, height: 15)
    }

    var titleLabel: some View {
        Text(Strings.ChooseCustomLocationView.titleLabel)
            .font(Fonts.boldTitle4)
            .foregroundColor(.darkBlue)
    }
    
    var confirmButton: some View {
        Button(action: {
            isConfirmCreatingSessionActive.toggle()
        }, label: {
            Text(Strings.Commons.continue)
                .bold()
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
