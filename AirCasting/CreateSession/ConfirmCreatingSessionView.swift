//
//  ConfirmCreatingSession.swift
//  AirCasting
//
//  Created by Anna Olak on 22/02/2021.
//

import SwiftUI
import CoreLocation

struct ConfirmCreatingSessionView: View {
    var sessionType = "mobile"
    var sessionName = "Ania's microphone session"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 50) {
            Text("Are you ready?")
                .font(Font.moderate(size: 24, weight: .bold))
                .foregroundColor(.darkBlue)
                
            VStack(alignment: .leading, spacing: 15) {
                Text("Your \(sessionType) session \(sessionName) is ready to start gathering data.")
                Text("Move to your starting location, confirm your location is accurate on the map, then press the start recording button below.")
            }
            .font(Font.muli(size: 16))
            .foregroundColor(Color.aircastingGray)
            .multilineTextAlignment(.leading)
            .lineSpacing(9.0)
            
            GoogleMapView(pathPoints: [], values: [])
                        
            Button(action: {}, label: {
                Text("Start recording")
                    .bold()
            })
            .buttonStyle(BlueButtonStyle())
        }
        .padding()
    }
}

struct ConfirmCreatingSession_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmCreatingSessionView()
    }
}
