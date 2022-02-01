// Created by Lunar on 11/08/2021.
//

import AirCastingStyling
import SwiftUI

struct ChooseCustomLocationView: View {
    @State private var isConfirmCreatingSessionActive: Bool = false
    @State private var location = ""
    @State var placePickerPresented: Bool = false
    @State var isLocationPopupPresented = false
    @Binding var creatingSessionFlowContinues: Bool
    var sessionName: String
    let baseURL: BaseURLProvider

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
            PlacePicker(placePickerDismissed: $placePickerPresented, address: $location)
        }
        .onChange(of: placePickerPresented, perform: { value in
            // The reason for this is to prevent map from multiple times refreshing after first map update
            placePickerPresented ? (placePickerPresented = false) : nil
        })
        .padding()
    }

    var mapGoogle: some View {
        GoogleMapView(pathPoints: [], placePickerDismissed: $placePickerPresented, isUserInteracting: Binding.constant(true), mapNotes: .constant([]))
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
                                                    baseURL: baseURL,
                                                    sessionName: sessionName),
            isActive: $isConfirmCreatingSessionActive,
            label: {
                EmptyView()
            }
        )
    }
}
