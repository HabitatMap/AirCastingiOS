// Created by Lunar on 11/08/2021.
//

import SwiftUI
import AirCastingStyling
import CoreLocation

struct LocationPopUpView: View {
    @EnvironmentObject var tracker: LocationTracker
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
            }, label: {
                Text(Strings.ConfirmCreatingSessionView.startRecording)
                    .bold()
            })
            .buttonStyle(BlueButtonStyle())
        }
        .sheet(isPresented: $isLocationPopupPresented) {
            PlacePicker(address: $location)
        }
        .padding()
    }
    
    var mapGoogle: some View {
        GoogleMapView(pathPoints: tracker.googleLocation)
    }
    
    var dot: some View {
        Capsule()
            .fill(Color.blue)
            .frame(width: 10, height: 10)
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
