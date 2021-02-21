//
//  ConfirmCreatingSession.swift
//  AirCasting
//
//  Created by Anna Olak on 22/02/2021.
//

import SwiftUI
import CoreLocation

struct ConfirmCreatingSession: View {
    var sessionType = "mobile"
    var sessionName = "Ania's microphone session"
    
    var body: some View {
        VStack {
            Text("Are you ready?")
                .font(Font.moderate(size: 24, weight: .bold))
                .foregroundColor(.darkBlue)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 15)
            Text("Your \(sessionType) session \(sessionName) is ready to start gathering data.")
                .font(Font.muli(size: 16))
                .foregroundColor(Color.aircastingGray)
                .multilineTextAlignment(.leading)
                .lineSpacing(9.0)
                .padding(.bottom, 15)
            Text("Move to your starting location, confirm your location is accurate on the map, then press the start recording button below.")
                .font(Font.muli(size: 16))
                .foregroundColor(Color.aircastingGray)
                .multilineTextAlignment(.leading)
                .lineSpacing(9.0)
                        
            Spacer()
            Button(action: {}, label: {
                Text("Start recording")
                    .bold()
            })
//            .frame(maxWidth: 250)
            .buttonStyle(BlueButtonStyle())
        }
        .padding()
    }
}

struct ConfirmCreatingSession_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmCreatingSession()
    }
}
