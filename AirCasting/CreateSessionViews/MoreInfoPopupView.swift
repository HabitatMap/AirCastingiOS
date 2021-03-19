//
//  MoreInfoPopupView.swift
//  AirCasting
//
//  Created by Lunar on 18/03/2021.
//

import SwiftUI

struct MoreInfoPopupView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Session types")
                .font(Font.moderate(size: 28, weight: .bold))
                .foregroundColor(.accentColor)
            Text("If you plan on moving around with the AirBeam3 while recording air quality measurement, configure the AirBeam to record a mobile session. When recording a mobile AirCasting session, measurements are created, timestamped, and geolocated once per second.")
            Text("If you plan to leave the AirBeam3 indoors or hang it outside then configure it to record a fixed session. When recording fixed AirCasting sessions, measurements are created and timestamped once per minute, and geocoordinates are fixed to a set location.")
        }
        .font(Font.muli(size: 16))
        .lineSpacing(12)
        .foregroundColor(.aircastingGray)
        .padding()
    }
}

struct MoreInfoPopupView_Previews: PreviewProvider {
    static var previews: some View {
        MoreInfoPopupView()
    }
}
