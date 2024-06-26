// Created by Lunar on 10/11/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct StandaloneSessionCardView: View {
    let session: SessionEntity
    @EnvironmentObject private var tabSelection: TabBarSelector
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @EnvironmentObject var selectedSection: SelectedSection
    @Injected private var networkChecker: NetworkChecker
    @InjectedObject private var userSettings: UserSettings
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
            Text(Strings.StandaloneSessionCardView.heading)
                .font(Fonts.moderateBoldHeading1)
                .foregroundColor(.darkBlue)
                .multilineTextAlignment(.center)
            Text(Strings.StandaloneSessionCardView.description)
                .font(Fonts.moderateRegularHeading3)
                .multilineTextAlignment(.center)
            finishAndSyncButton
            finishAndDontSyncButton
            .padding()
        }
        .alert(item: $alert, content: { $0.makeAlert() })
        .padding()
    }

    var finishAndSyncButton: some View {
        Button(Strings.StandaloneSessionCardView.finishAndSyncButtonLabel) {
            if networkChecker.connectionAvailable {
                guard !userSettings.syncOnlyThroughWifi || networkChecker.isUsingWifi else {
                    alert = InAppAlerts.noWifiNetworkSyncAlert()
                    return
                }
                alert = InAppAlerts.finishAndSyncAlert(sessionName: session.name) {
                    self.finishSessionAndSyncAlertAction()
                }
            } else {
                alert = InAppAlerts.noNetworkAlert()
            }
        }
        .font(Fonts.muliBoldHeading1)
        .buttonStyle(BlueButtonStyle())
    }

    var finishAndDontSyncButton: some View {
        Button(Strings.StandaloneSessionCardView.finishAndDontSyncButtonLabel) {
            alert = InAppAlerts.finishSessionAlert(sessionName: session.name) {
                self.finishSessionAlertAction()
            }
        }
        .foregroundColor(.accentColor)
        .font(Fonts.moderateRegularHeading2)
    }

    func finishSessionAndSyncAlertAction() {
        finishAndSyncButtonTapped.finishAndSyncButtonWasTapped = true
        tabSelection.update(to: .createSession)
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
