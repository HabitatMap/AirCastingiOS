// Created by Lunar on 11/08/2021.
//

import SwiftUI
import AirCastingStyling
import CoreLocation

struct LocationPopUpView: View {
    
    @State private var text = ""
    @State private var location = ""
    @State private var coordi: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 50.0, longitude: 19.0)
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
                GoogleMapView(pathPoints: [PathPoint(location: coordi, measurement: 20.0)])
                dot
            }
            Button(action: {
            }, label: {
                Text(Strings.ConfirmCreatingSessionView.startRecording)
                    .bold()
            })
            .buttonStyle(BlueButtonStyle())
        } .sheet(isPresented: $isLocationPopupPresented) {
            PlacePicker(address: $location, coordinates: $coordi)
        }
        .padding()
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

struct LocationPopUpView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPopUpView(creatingSessionFlowContinues: .constant(true))
    }
}
