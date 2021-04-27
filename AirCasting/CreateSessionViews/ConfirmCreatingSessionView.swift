//
//  ConfirmCreatingSession.swift
//  AirCasting
//
//  Created by Anna Olak on 22/02/2021.
//

import SwiftUI
import CoreLocation

struct ConfirmCreatingSessionView: View {
    @State var isActive : Bool = false
    
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @State private var didStartRecordingSession = false
    @EnvironmentObject private var microphoneManager: MicrophoneManager
    @EnvironmentObject private var tabSelection: TabBarSelection
    
    @Binding var creatingSessionFlowContinues : Bool
    
    var sessionName: String
    private var sessionType: String { (sessionContext.sessionType ?? .fixed).description.lowercased() }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Are you ready?")
                .font(Font.moderate(size: 24, weight: .bold))
                .foregroundColor(.darkBlue)
                
            VStack(alignment: .leading, spacing: 15) {
                Text("Your ")
                    + Text(sessionType)
                        .foregroundColor(.accentColor)
                    + Text(" session ")
                    + Text(sessionName)
                        .foregroundColor(.accentColor)
                    + Text(" is ready to start gathering data.")
                Text("Move to your starting location, confirm your location is accurate on the map, then press the start recording button below.")
            }
            .font(Font.muli(size: 16))
            .foregroundColor(Color.aircastingGray)
            .multilineTextAlignment(.leading)
            .lineSpacing(9.0)
            
            GoogleMapView(pathPoints: [], thresholds: [], isMyLocationEnabled: true)
                        
            Button(action: {
                if (sessionContext.deviceType == DeviceType.MIC) {
                    sessionContext.startMicrophoneSession(microphoneManager: microphoneManager)
                } else {
                    sessionContext.setupAB()
                }
                self.creatingSessionFlowContinues = false
                tabSelection.selection = TabBarSelection.Tab.dashboard
            }, label: {
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
        ConfirmCreatingSessionView(creatingSessionFlowContinues: .constant(true), sessionName: "Ania's microphone session")
    }
}
