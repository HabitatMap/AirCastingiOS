// Created by Lunar on 10/11/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct StandaloneSessionCardView: View {
    let session: SessionEntity
    @EnvironmentObject private var tabSelection: TabBarSelector
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @EnvironmentObject private var standaloneSessionToSyncAndFinish: StandaloneSessionToSyncAndFinish
    @EnvironmentObject var selectedSection: SelectedSection
    @Injected private var networkChecker: NetworkChecker
    @InjectedObject private var userSettings: UserSettings
    @StateObject private var reconnectViewModel: ReconnectSessionCardViewModel
    @State private var alert: AlertInfo?

    init(session: SessionEntity) {
        self.session = session
        _reconnectViewModel = StateObject(wrappedValue: ReconnectSessionCardViewModel(session: session))
    }
    
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
            reconnectButton
            finishAndSyncButton
            finishAndDontSyncButton
            .padding()
        }
        // SwiftUI quirk: stacking multiple `.alert(item:)` modifiers (here:
        // card's own `alert` + `reconnectViewModel.alert`) plus the embedded
        // SessionHeaderView's `.alert(_:isPresented:)` on a sibling view tree
        // causes the card's alerts to never fire. Symptom is the user-reported
        // "Finish & sync / Finish & don't sync buttons do nothing" — the
        // button-tap closure sets `alert = ...` but no UIAlert appears.
        //
        // Workaround: present each alert via iOS 15+ `.alert(_:isPresented:)`
        // bound to a Bool. The Bool-binding API is not affected by the
        // `.alert(item:)` shadowing bug. Native UIAlert presentation
        // (centered popup, V1 visual parity) is preserved — `.confirmationDialog`
        // would render an action sheet from the bottom instead.
        .alert(
            alert?.title ?? "",
            isPresented: Binding(
                get: { alert != nil },
                set: { newValue in if !newValue { alert = nil } }
            ),
            presenting: alert,
            actions: { info in
                ForEach(Array(info.buttons.enumerated()), id: \.offset) { _, type in
                    switch type {
                    case .cancel(let title):
                        Button(title, role: .cancel, action: { alert = nil })
                    case .default(let title, nil):
                        Button(title, action: { alert = nil })
                    case .default(let title, let action):
                        Button(title, action: { action?(); alert = nil })
                    }
                }
            },
            message: { info in Text(info.message) }
        )
        .alert(item: $reconnectViewModel.alert, content: { $0.makeAlert() })
        .padding()
    }

    var reconnectButton: some View {
        Button(reconnectViewModel.buttonLabel) {
            reconnectViewModel.onRecconectTap()
        }
        .disabled(reconnectViewModel.connectingState != .idle)
        .font(Fonts.muliBoldHeading1)
        .buttonStyle(BlueButtonStyle())
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
        standaloneSessionToSyncAndFinish.setSession(session.uuid,
                                                    isV2: session.deviceFirmwareVersion == .v2)
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
