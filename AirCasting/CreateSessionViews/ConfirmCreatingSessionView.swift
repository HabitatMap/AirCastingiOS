//
//  ConfirmCreatingSession.swift
//  AirCasting
//
//  Created by Anna Olak on 22/02/2021.
//

import SwiftUI
import CoreLocation

struct ConfirmCreatingSessionView: View {
    
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @State private var didStartRecordingSession = false
    var sessionName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Are you ready?")
                .font(Font.moderate(size: 24, weight: .bold))
                .foregroundColor(.darkBlue)
                
            VStack(alignment: .leading, spacing: 15) {
                Text("Your \(showSessionType()) session \(sessionName) is ready to start gathering data.")
                Text("Move to your starting location, confirm your location is accurate on the map, then press the start recording button below.")
            }
            .font(Font.muli(size: 16))
            .foregroundColor(Color.aircastingGray)
            .multilineTextAlignment(.leading)
            .lineSpacing(9.0)
            
            GoogleMapView(pathPoints: [], values: [], isMyLocationEnabled: true)
                        
            Button(action: {
                sessionContext.setupAB()
                didStartRecordingSession = true
            }, label: {
                Text("Start recording")
                    .bold()
            })
            .buttonStyle(BlueButtonStyle())
            .background(
                NavigationLink(destination: ChooseSessionTypeView(),
                               isActive: $didStartRecordingSession) {
                    EmptyView()
                })
        }
        .padding()
    }
    
    func showSessionType() -> String {
        return sessionContext.sessionType == SessionType.MOBILE ? "mobile" : "fixed"
    }
}

struct ConfirmCreatingSession_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmCreatingSessionView(sessionName: "tests")
    }
}
