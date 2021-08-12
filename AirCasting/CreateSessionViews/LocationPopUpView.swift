// Created by Lunar on 11/08/2021.
//

import SwiftUI
import AirCastingStyling
import CoreLocation

struct LocationPopUpView: View {
    let sessionCreator: SessionCreator
    @State var sessionName: String = ""
    @State private var isConfirmCreatingSessionActive: Bool = false
    @State private var text = ""
    @State private var location = ""
    @State private var lan: Double = 50.0
    @State private var long: Double = 19.0
    @State var isLocationPopupPresented = false
    @Binding var creatingSessionFlowContinues: Bool
    var body: some View {
        VStack() {
            titleLabel
            createTextfield(placeholder: "Session location", binding: $location)
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
                Text(Strings.ConfirmCreatingSessionView.startRecording)
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
        GoogleMapView(pathPoints: [], isMyLocationEnabled: true)
    }
    
    var dot: some View {
        Capsule()
            .fill(Color.blue)
            .frame(width: 15, height: 15)
    }
    
    var titleLabel: some View {
        Text("Search the adress and ajust the marker to indicate an exact placement of Your AirBeam")
            .font(Font.moderate(size: 24, weight: .bold))
            .foregroundColor(.darkBlue)
    }
}

//struct LocationPopUpView_Previews: PreviewProvider {
//    static var previews: some View {
//        LocationPopUpView(self)
//    }
//}
