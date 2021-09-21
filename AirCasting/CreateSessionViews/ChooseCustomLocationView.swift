// Created by Lunar on 11/08/2021.
//

import AirCastingStyling
import SwiftUI

struct ChooseCustomLocationView: View {
    @State private var isConfirmCreatingSessionActive: Bool = false
    @State private var location = ""
    @State var placePickerDismissed: Bool = false
    @State var isLocationPopupPresented = false
    @Binding var creatingSessionFlowContinues: Bool
    @Binding var sessionName: String
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
            PlacePicker(placePickerDismissed: $placePickerDismissed, address: $location)
        }
        .onChange(of: placePickerDismissed, perform: { value in
            placePickerDismissed ? (placePickerDismissed = false) : nil
        })
        .padding()
    }

    var mapGoogle: some View {
        GoogleMapView(pathPoints: [], placePickerDismissed: $placePickerDismissed)
    }

    var dot: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 15, height: 15)
    }

    var titleLabel: some View {
        Text(Strings.ChooseCustomLocationView.titleLabel)
            .font(Font.moderate(size: 24, weight: .bold))
            .foregroundColor(.darkBlue)
    }
    
    var confirmButton: some View {
        Button(action: {
            isConfirmCreatingSessionActive.toggle()
        }, label: {
            Text(Strings.ChooseCustomLocationView.continueButton)
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

