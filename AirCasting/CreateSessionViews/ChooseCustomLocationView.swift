// Created by Lunar on 11/08/2021.
//

import AirCastingStyling
import SwiftUI

struct ChooseCustomLocationView: View {
    let sessionCreator: SessionCreator
    @State private var isConfirmCreatingSessionActive: Bool = false
    @State private var location = ""
    @State var isLocationPopupPresented = false
    @Binding var creatingSessionFlowContinues: Bool
    @Binding var sessionName: String

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
            Button(action: {
                isConfirmCreatingSessionActive.toggle()
            }, label: {
                Text(Strings.ChooseCustomLocationView.continueButton)
                    .bold()
            }).background(
                NavigationLink(
                    destination: ConfirmCreatingSessionView(sessionCreator: sessionCreator,
                                                            creatingSessionFlowContinues: $creatingSessionFlowContinues,
                                                            sessionName: sessionName),
                    isActive: $isConfirmCreatingSessionActive,
                    label: {
                        EmptyView()
                    }
                ))
                .buttonStyle(BlueButtonStyle())
        }
        .sheet(isPresented: $isLocationPopupPresented) {
            PlacePicker(address: $location)
        }
        .padding()
    }

    var mapGoogle: some View {
        GoogleMapView(pathPoints: [])
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
}

#if DEBUG
struct LocationPopUpView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseCustomLocationView(sessionCreator: PreviewSessionCreator(), creatingSessionFlowContinues: .constant(true), sessionName: .constant("true"))
    }
}
#endif
