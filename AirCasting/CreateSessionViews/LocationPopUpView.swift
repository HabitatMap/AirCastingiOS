// Created by Lunar on 11/08/2021.
//

import SwiftUI
import AirCastingStyling

struct LocationPopUpView: View {
    var body: some View {
        VStack() {
            titleLabel
            GoogleMapView(pathPoints: [])
                .padding()
            Button(action: {
            }, label: {
                Text(Strings.ConfirmCreatingSessionView.startRecording)
                    .bold()
            })
            .buttonStyle(BlueButtonStyle())
        }.padding()
    }
    
    var titleLabel: some View {
        Text("Search the adress and ajust the marker to indicate an exact placement of Your AirBeam")
            .font(Font.moderate(size: 24, weight: .bold))
            .foregroundColor(.darkBlue)
    }
}

struct LocationPopUpView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPopUpView()
    }
}
