//
//  ConfirmCreatingSession.swift
//  AirCasting
//
//  Created by Anna Olak on 22/02/2021.
//

import SwiftUI
import CoreLocation
import AirCastingStyling

struct ConfirmCreatingSessionView: View {
    @State private var isActive: Bool = false
    @State private var error: NSError? {
        didSet {
            isPresentingAlert = error != nil
        }
    }
    @State private var isPresentingAlert: Bool = false
    @EnvironmentObject var selectedSection: SelectSection
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
            Alert(title: Text(Strings.ConfirmCreatingSessionView.alertTitle), message: Text(error?.localizedDescription ?? Strings.ConfirmCreatingSessionView.alertMessage), dismissButton: .default(Text(Strings.ConfirmCreatingSessionView.alertOK), action: {
                error = nil
            }))
        }
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 40) {
            ProgressView(value: 0.90)
            areYouReady
            confirmInfo
            GoogleMapView(pathPoints: [], isMyLocationEnabled: true)
            confirmButton
        }.padding()
    }
    
    private var areYouReady: some View {
        Text(Strings.ConfirmCreatingSessionView.contentViewTitle)
            .font(Font.moderate(size: 24, weight: .bold))
            .foregroundColor(.darkBlue)
    }
    
    private var confirmInfo: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(Strings.ConfirmCreatingSessionView.contentViewText_1)
                + Text(sessionType)
                .foregroundColor(.accentColor)
                + Text(Strings.ConfirmCreatingSessionView.contentViewText_2)
                + Text(sessionName)
                .foregroundColor(.accentColor)
                + Text(Strings.ConfirmCreatingSessionView.contentViewText_3)
            Text(Strings.ConfirmCreatingSessionView.contentViewText_4)
        }
        .font(Font.muli(size: 16))
        .foregroundColor(Color.aircastingGray)
        .multilineTextAlignment(.leading)
        .lineSpacing(9.0)
    }
    
    private var confirmButton: some View {
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
            Text(Strings.ConfirmCreatingSessionView.actionTitle)
                .bold()
        })
        .buttonStyle(BlueButtonStyle())
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
