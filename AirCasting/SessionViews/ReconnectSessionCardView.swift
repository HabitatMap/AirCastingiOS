// Created by Lunar on 21/10/2022.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct ReconnectSessionCardView: View {
    let session: SessionEntity
    @EnvironmentObject private var tabSelection: TabBarSelection
    @EnvironmentObject var selectedSection: SelectedSection
    @State private var alert: AlertInfo?
    
    var body: some View {
        Group {
            Spacer()
            VStack(alignment: .leading, spacing: 5) {
                header
                content
            }
            .foregroundColor(.aircastingGray)
            .padding()
            .background(
                Color.aircastingBackground
                    .cardShadow()
            )
            .overlay(Rectangle().frame(width: nil, height: 4, alignment: .top).foregroundColor(Color.red), alignment: .top)
        }
    }
    
    var header: some View {
        SessionHeaderView(
            action: {},
            isExpandButtonNeeded: false,
            isMenuNeeded: false,
            isCollapsed: .constant(false),
            session: session)
    }
    
    var content: some View {
        VStack(spacing: 15) {
            Text(Strings.ReconnectSessionCardView.heading)
                .font(Fonts.moderateBoldHeading1)
                .foregroundColor(.darkBlue)
                .multilineTextAlignment(.center)
            Text(Strings.ReconnectSessionCardView.description)
                .font(Fonts.moderateRegularHeading3)
                .multilineTextAlignment(.center)
            reconnectionLabel
            finishAndDontSyncButton
                .padding()
        }
        .alert(item: $alert, content: { $0.makeAlert() })
        .padding()
    }
    
    var reconnectionLabel: some View {
        Button {
            //
        } label: {
            ZStack(alignment: .center) {
                HStack(alignment: .center) {
                    Text(Strings.ReconnectSessionCardView.reconnectLabel)
                }
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing)
                }
            }
        }
        .font(Fonts.muliBoldHeading1)
        .buttonStyle(BlueButtonStyle())
    }
    
    var finishAndDontSyncButton: some View {
        Button(Strings.ReconnectSessionCardView.finishSessionLabel) {
            alert = InAppAlerts.finishSessionAlert(sessionName: session.name) {
                self.finishSessionAlertAction()
            }
        }
        .foregroundColor(.accentColor)
        .font(Fonts.moderateRegularHeading2)
    }
    
    func finishSessionAndSyncAlertAction() {
        tabSelection.selection = .createSession
        selectedSection.mobileSessionWasFinished = true
    }
    
    func finishSessionAlertAction() {
        let sessionStopper = Resolver.resolve(SessionStoppable.self, args: self.session)
        do {
            try sessionStopper.stopSession()
            selectedSection.mobileSessionWasFinished = true
        } catch {
            Log.info("error when stpoing session - \(error)")
        }
    }
}
