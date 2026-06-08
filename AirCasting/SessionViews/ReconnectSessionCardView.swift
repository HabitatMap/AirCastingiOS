// Created by Lunar on 21/10/2022.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct ReconnectSessionCardView: View {
    @StateObject var viewModel: ReconnectSessionCardViewModel
    @EnvironmentObject var selectedSection: SelectedSection
    @EnvironmentObject private var tabSelection: TabBarSelector
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    @EnvironmentObject private var standaloneSessionToSyncAndFinish: StandaloneSessionToSyncAndFinish
    @State private var finishAndSyncAlert: AlertInfo?

    var body: some View {
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
    
    var header: some View {
        SessionHeaderView(
            action: {},
            isExpandButtonNeeded: false,
            isMenuNeeded: false,
            isCollapsed: .constant(false),
            session: viewModel.session)
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
            // Phase 6: V2 devices get the BLE manual-sync path. The fullScreenCover
            // sync wizard handles the "device must be connected" prerequisite —
            // it scans, reconnects, then runs `StartBleSync 0x16` against the
            // existing standalone-session UUID. For V1 (which used SD-card sync
            // and required a physical "Unplug AirBeam" step) we never offered a
            // sync-from-disconnected entry point; keep that gap in V1.
            if viewModel.session.deviceFirmwareVersion == .v2 {
                finishAndSyncButton
            }
            finishAndDontSyncButton
                .padding()
        }
        // Stacked `.alert(item:)` modifiers + SessionHeaderView's own alert
        // shadow each other in SwiftUI, leaving the card's "Finish session" /
        // "Finish & sync" buttons silent. Use the iOS 15+ Bool-binding alert
        // API instead — same native UIAlert visual as V1 (centered popup,
        // matches screenshot from the previous release), unaffected by the
        // `.alert(item:)` shadowing bug.
        .alert(
            viewModel.alert?.title ?? finishAndSyncAlert?.title ?? "",
            isPresented: Binding(
                get: { viewModel.alert != nil || finishAndSyncAlert != nil },
                set: { newValue in
                    if !newValue {
                        viewModel.alert = nil
                        finishAndSyncAlert = nil
                    }
                }
            ),
            presenting: viewModel.alert ?? finishAndSyncAlert,
            actions: { info in
                ForEach(Array(info.buttons.enumerated()), id: \.offset) { _, type in
                    switch type {
                    case .cancel(let title):
                        Button(title, role: .cancel, action: {
                            viewModel.alert = nil
                            finishAndSyncAlert = nil
                        })
                    case .default(let title, nil):
                        Button(title, action: {
                            viewModel.alert = nil
                            finishAndSyncAlert = nil
                        })
                    case .default(let title, let action):
                        Button(title, action: {
                            action?()
                            viewModel.alert = nil
                            finishAndSyncAlert = nil
                        })
                    }
                }
            },
            message: { info in Text(info.message) }
        )
        .padding()
    }

    var finishAndSyncButton: some View {
        Button(Strings.StandaloneSessionCardView.finishAndSyncButtonLabel) {
            finishAndSyncAlert = InAppAlerts.finishAndSyncAlert(sessionName: viewModel.session.name) {
                self.finishAndSyncAction()
            }
        }
        .font(Fonts.muliBoldHeading1)
        .buttonStyle(BlueButtonStyle())
    }

    private func finishAndSyncAction() {
        finishAndSyncButtonTapped.finishAndSyncButtonWasTapped = true
        standaloneSessionToSyncAndFinish.setSession(viewModel.session.uuid, isV2: true)
        tabSelection.update(to: .createSession)
        selectedSection.mobileSessionWasFinished = true
    }
    
    var reconnectionLabel: some View {
        Button {
            viewModel.onRecconectTap()
        } label: {
            ZStack(alignment: .center) {
                HStack(alignment: .center) {
                    Text(viewModel.buttonLabel)
                }
                if viewModel.connectingState != .idle {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing)
                    }
                }
            }
        }
        .font(Fonts.muliBoldHeading1)
        .buttonStyle(BlueButtonStyle())
        .disabled(viewModel.connectingState != .idle)
    }
    
    var finishAndDontSyncButton: some View {
        Button(Strings.ReconnectSessionCardView.finishSessionLabel) {
            viewModel.onFinishDontSyncTapped {
                selectedSection.mobileSessionWasFinished = true
            }
        }
        .foregroundColor(.accentColor)
        .font(Fonts.moderateRegularHeading2)
    }
}
