//
//  ConfirmCreatingSession.swift
//  AirCasting
//
//  Created by Anna Olak on 22/02/2021.
//

import SwiftUI
import CoreLocation

struct ConfirmCreatingSessionView: View {
    @State private var isActive: Bool = false
    @State private var error: NSError? {
        didSet {
            isPresentingAlert = error != nil
        }
    }
    @State private var isPresentingAlert: Bool = false
    
    @EnvironmentObject private var sessionContext: CreateSessionContext
    let sessionCreator: SessionCreator
    @State private var didStartRecordingSession = false
    @EnvironmentObject private var tabSelection: TabBarSelection
    
    @Binding var creatingSessionFlowContinues : Bool
    
    var sessionName: String
    private var sessionType: String { (sessionContext.sessionType ?? .fixed).description.lowercased() }
    
    var body: some View {
        LoadingView(isShowing: $isActive) {
            contentViewWithAlert
        }
    }

    private var contentViewWithAlert: some View {
        contentView.alert(isPresented: $isPresentingAlert) {
            Alert(title: Text("Failure"), message: Text(error?.localizedDescription ?? "Failed to create session"), dismissButton: .default(Text("Got it!"), action: {
                error = nil
            }))
        }
    }
    
    private var contentView: some View {
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
                isActive = true
                sessionCreator.createSession(sessionContext) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            self.creatingSessionFlowContinues = false
                            tabSelection.selection = TabBarSelection.Tab.dashboard
                        case .failure(let error):
                            self.error = error as NSError
                            Log.warning("Failed to create session \(error)")
                        }
                        isActive = false
                    }
                }
            }, label: {
                Text("Start recording")
                    .bold()
            })
            .buttonStyle(BlueButtonStyle())
        }.padding()
    }
}

#if DEBUG
struct ConfirmCreatingSession_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmCreatingSessionView(sessionCreator: PreviewSessionCreator(),
                                   creatingSessionFlowContinues: .constant(true),
                                   sessionName: "Ania's microphone session")
            .environmentObject(CreateSessionContext())
            .previewDevice(PreviewDevice(rawValue: "iPhone 12 mini"))
    }
}
#endif
