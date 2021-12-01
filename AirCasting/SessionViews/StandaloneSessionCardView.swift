// Created by Lunar on 10/11/2021.
//

import SwiftUI
import AirCastingStyling

struct StandaloneSessionCardView: View {
    let session: SessionEntity
    let sessionStopperFactory: SessionStoppableFactory
    let sessionSynchronizer: SessionSynchronizer
    @EnvironmentObject private var sdSyncController: SDSyncController
    @EnvironmentObject private var urlProvider: UserDefaultsBaseURLProvider
    @EnvironmentObject private var tabSelection: TabBarSelection
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @EnvironmentObject var networkChecker: NetworkChecker
    @State private var alert: AlertInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            content
        }
        .font(Fonts.regularHeading4)
        .foregroundColor(.aircastingGray)
        .padding()
        .background(Color.white
                        .shadow(color: .sessionCardShadow, radius: 9, x: 0, y: 1))
        .overlay(Rectangle().frame(width: nil, height: 4, alignment: .top).foregroundColor(Color.red), alignment: .top)
    }

    var header: some View {
        SessionHeaderView(
            action: {},
            isExpandButtonNeeded: false,
            isMenuNeeded: false,
            isCollapsed: .constant(false),
            session: session,
            sessionStopperFactory: sessionStopperFactory,
            measurementStreamStorage: measurementStreamStorage,
            sessionSynchronizer: sessionSynchronizer)
    }

    var content: some View {
        VStack(spacing: 15) {
            Text(Strings.StandaloneSessionCardView.heading)
                .font(Fonts.boldHeading3)
                .foregroundColor(.darkBlue)
            Text(Strings.StandaloneSessionCardView.description)
                .multilineTextAlignment(.center)
            finishAndSyncButton
            finishAndDontSyncButton
            .padding()
        }
        .alert(item: $alert, content: { alert in
            if alert.id == .finishSessionAlert {
                return Alert(title: alert.title,
                             message: alert.message,
                             primaryButton: .default(alert.buttonTitle, action: {
                    finishSessionAlertAction(sessionStopper: sessionStopperFactory.getSessionStopper(for: session))
                }),
                             secondaryButton: .cancel())
            } else if alert.id == .finishSessionAndSyncAlert {
                return Alert(title: alert.title,
                             message: alert.message,
                             primaryButton: .default(alert.buttonTitle, action: {
                    finishSessionAndSyncAlertAction()
                }), secondaryButton: .cancel())
            }
            return Alert(title: alert.title,
                         message: alert.message,
                         dismissButton: .default(alert.buttonTitle))
        })
        .padding()
    }

    var finishAndSyncButton: some View {
        Button(Strings.StandaloneSessionCardView.finishAndSyncButtonLabel) {
            if networkChecker.connectionAvailable {
                alert = InAppAlerts.finishAndSyncAlert(sessionName: session.name)
            } else {
                alert = InAppAlerts.noNetworkAlert()
            }
        }
        .buttonStyle(BlueButtonStyle())
    }

    var finishAndDontSyncButton: some View {
        Button(Strings.StandaloneSessionCardView.finishAndDontSyncButtonLabel) {
            alert = InAppAlerts.finishSessionAlert(sessionName: session.name)
        }
        .foregroundColor(.accentColor)
    }

    func finishSessionAndSyncAlertAction() {
        let sessionStopper = sessionStopperFactory.getSessionStopper(for: session)
        do {
            try sessionStopper.stopSession()
        } catch {
            Log.info("error when stpoing session - \(error)")
        }
        finishAndSyncButtonTapped.finishAndSyncButtonWasTapped = true
        tabSelection.selection = .createSession
    }
    
    func finishSessionAlertAction(sessionStopper: SessionStoppable) {
        do {
            try sessionStopper.stopSession()
        } catch {
            Log.info("error when stpoing session - \(error)")
        }
    }
}

#if DEBUG
struct StandaloneSessionCard_Previews: PreviewProvider {
    static var previews: some View {
        StandaloneSessionCardView(session: SessionEntity.mock, sessionStopperFactory: SessionStoppableFactoryDummy(), sessionSynchronizer: DummySessionSynchronizer(), measurementStreamStorage: PreviewMeasurementStreamStorage())
            .environmentObject(DummyURLProvider())
    }
}
#endif
