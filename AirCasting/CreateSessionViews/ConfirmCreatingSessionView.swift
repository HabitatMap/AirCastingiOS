//
//  ConfirmCreatingSession.swift
//  AirCasting
//
//  Created by Anna Olak on 22/02/2021.
//

import AirCastingStyling
import CoreLocation
import SwiftUI

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
    @EnvironmentObject private var locationTracker: LocationTracker
    let sessionCreator: SessionCreator
    @State private var didStartRecordingSession = false
    @EnvironmentObject private var tabSelection: TabBarSelection

    @Binding var creatingSessionFlowContinues: Bool

    var sessionName: String
    private var sessionType: String { (sessionContext.sessionType ?? .fixed).description.lowercased() }

    var body: some View {
        LoadingView(isShowing: $isActive) {
            contentViewWithAlert
        }
    }

    private var contentViewWithAlert: some View {
        contentView.alert(isPresented: $isPresentingAlert) {
            Alert(title: Text(Strings.ConfirmCreatingSessionView.alertTitle), message: Text(error?.localizedDescription ?? Strings.ConfirmCreatingSessionView.alertMessage), dismissButton: .default(Text(Strings.ConfirmCreatingSessionView.alertOK), action: { error = nil
            }))
        }
    }

    private var someText: some View {
        Text(Strings.ConfirmCreatingSessionView.contentViewText_1)
            + Text(sessionType)
            .foregroundColor(.accentColor)
            + Text(Strings.ConfirmCreatingSessionView.contentViewText_2)
            + Text(sessionName)
            .foregroundColor(.accentColor)
            + text
    }

    private var text: Text {
        Text(Strings.ConfirmCreatingSessionView.contentViewText_3)
            + Text(Strings.ConfirmCreatingSessionView.contentViewText_4)
    }

    var dot: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 15, height: 15)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 40) {
            ProgressView(value: 0.95)
            Text(Strings.ConfirmCreatingSessionView.contentViewTitle)
                .font(Font.moderate(size: 24, weight: .bold))
                .foregroundColor(.darkBlue)

            VStack(alignment: .leading, spacing: 15) {
                someText
            }
            .font(Font.muli(size: 16))
            .foregroundColor(Color.aircastingGray)
            .multilineTextAlignment(.leading)
            .lineSpacing(9.0)
            ZStack {
                if sessionContext.sessionType == .mobile {
                    GoogleMapView(pathPoints: [], isMyLocationEnabled: true)
                } else {
                    GoogleMapView(pathPoints: [])
                    dot
                }
            }
            Button(action: {
                isActive = true
                sessionCreator.createSession(sessionContext) { result in

                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            self.creatingSessionFlowContinues = false
                            if sessionContext.sessionType == .mobile {
                                selectedSection.selectedSection = SelectedSection.mobileActive
                            } else {
                                selectedSection.selectedSection = SelectedSection.following
                            }
                            tabSelection.selection = TabBarSelection.Tab.dashboard
                        case .failure(let error):
                            self.error = error as NSError
                            Log.warning("Failed to create session \(error)")
                        }
                        isActive = false
                    }
                }
            }, label: {
                Text(Strings.ConfirmCreatingSessionView.startRecording)
                    .bold()
            })
                .buttonStyle(BlueButtonStyle())
        }
            .padding()
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
