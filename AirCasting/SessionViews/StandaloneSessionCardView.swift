// Created by Lunar on 10/11/2021.
//

import SwiftUI
import AirCastingStyling

struct StandaloneSessionCardView: View {
    let session: SessionEntity
    let sessionStopperFactory: SessionStoppableFactory
    let sessionSynchronizer: SessionSynchronizer
    let measurementStreamStorage: MeasurementStreamStorage
    @State private var showingFinishAlert = false
    @State private var showingFinishAndSyncAlert = false
    @EnvironmentObject private var sdSyncController: SDSyncController
    @EnvironmentObject private var urlProvider: UserDefaultsBaseURLProvider
    @EnvironmentObject private var tabSelection: TabBarSelection
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped

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
            measurementStreamStorage: measurementStreamStorage
        )
    }

    var content: some View {
        VStack(spacing: 15) {
            Text(Strings.StandaloneSessionCardView.heading)
                .font(Fonts.boldHeading3)
                .foregroundColor(.darkBlue)
            Text(Strings.StandaloneSessionCardView.description)
                .multilineTextAlignment(.center)
            finishAndSyncButton
                .alert(isPresented: $showingFinishAndSyncAlert) {
                    finishAndSyncAlert(sessionName: session.name)
                }
            finishAndDontSyncButton
                .alert(isPresented: $showingFinishAlert) {
                    SessionViews.finishSessionAlert(sessionStopper: sessionStopperFactory.getSessionStopper(for: session), sessionName: session.name)
                }
            .padding()
        }
        .padding()
    }

    var finishAndSyncButton: some View {
        Button(Strings.StandaloneSessionCardView.finishAndSyncButtonLabel) {
            showingFinishAndSyncAlert = true
        }
        .buttonStyle(BlueButtonStyle())
    }

    var finishAndDontSyncButton: some View {
        Button(Strings.StandaloneSessionCardView.finishAndDontSyncButtonLabel) {
            showingFinishAlert = true
        }
        .foregroundColor(.accentColor)
    }

    func finishAndSyncAlert(sessionName: String?) -> Alert {
        Alert(title: Text(Strings.SessionHeaderView.finishAlertTitle) +
              Text(sessionName ?? Strings.SessionHeaderView.finishAlertTitle_2)
              +
              Text(" and sync from SD card?"),
              message: Text(Strings.SessionHeaderView.finishAlertMessage_1) +
              Text(Strings.SessionHeaderView.finishAlertMessage_2) +
              Text(Strings.SessionHeaderView.finishAlertMessage_3) +
              Text("\nSD card will be cleared afterwards"),
              primaryButton: .default(Text(Strings.SessionHeaderView.finishAlertButton), action: {
            finishAndSyncButtonTapped.finishAndSyncButtonWasTapped = true
            tabSelection.selection = .createSession
        }),
              secondaryButton: .cancel())
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
