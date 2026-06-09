//
//  SessionHeader.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//
import AirCastingStyling
import SwiftUI
import Resolver

struct SessionHeaderView: View {
    let action: () -> Void
    let isExpandButtonNeeded: Bool
    var isSensorTypeNeeded: Bool = true
    var isMenuNeeded = true
    var chevronIndicator: String {
        isCollapsed ? "chevron.down" : "chevron.up"
    }
    @Binding var isCollapsed: Bool
    private let standaloneModeController: StandaloneModeController = Resolver.resolve(StandaloneModeController.self,
                                                                                  args: StandaloneOrigin.user)
    @EnvironmentObject var selectedSection: SelectedSection
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var session: SessionEntity
    @State private var showingNoConnectionAlert = false
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    @State var showDeleteModal = false
    @State var showAddNoteModal = false
    @State var showShareModal = false
    @State var showEditView = false
    @State var detectEmailSent = false
    @State var showThresholdAlertModal = false
    @State private var isShowingFinishSessionAlert = false
    @State private var isShowingEmailSentAlert = false
    @State private var syncAndFinishViewModel: SyncAndFinishV2SessionViewModel? = nil
    
    var body: some View {
        if #available(iOS 15, *) {
            sessionHeader
                .sheet(isPresented: $showDeleteModal) {
                    DeleteView(viewModel: DefaultDeleteSessionViewModel(session: session),
                               deleteModal: $showDeleteModal)
                }
                .sheet(isPresented: $showShareModal) {
                    if session.locationless {
                        ShareLocationlessSessionView(viewModel: ShareLocationlessSessionViewModel(session: session, fileGenerationController: DefaultGenerateSessionFileController(fileGenerator: DefaultCSVFileGenerator(), fileZipper: SSZipFileZipper()), exitRoute: { showShareModal.toggle() }))
                    } else {
                        ShareSessionView(viewModel: DefaultShareSessionViewModel(session: session, apiClient: ShareSessionApi(), exitRoute: { result in
                                                showShareModal.toggle()
                            if result == .fileShared {
                                                    detectEmailSent = true
                                                }
                                            })).onDisappear(perform: {
                                                if detectEmailSent {
                                                    isShowingEmailSentAlert = true
                                                }
                                            })
                    }
                }
                .sheet(isPresented: $showEditView) {
                    editViewSheet
                }
                .sheet(isPresented: $showAddNoteModal) {
                    AddNoteView(viewModel: AddNoteViewModel(sessionUUID: session.uuid, withLocation: !session.locationless, exitRoute: { showAddNoteModal.toggle() }))
                }
                .sheet(isPresented: $showThresholdAlertModal) {
                    thresholdAlertSheet
                }
        } else {
            sessionHeader
                .background(
                    Group {
                        EmptyView()
                            .sheet(isPresented: $showDeleteModal) {
                                DeleteView(viewModel: DefaultDeleteSessionViewModel(session: session),
                                           deleteModal: $showDeleteModal)
                            }
                        EmptyView()
                            .sheet(isPresented: $showShareModal) {
                                if session.locationless {
                                    ShareLocationlessSessionView(viewModel: ShareLocationlessSessionViewModel(session: session, fileGenerationController: DefaultGenerateSessionFileController(fileGenerator: DefaultCSVFileGenerator(), fileZipper: SSZipFileZipper()), exitRoute: { showShareModal.toggle() }))
                                } else {
                                    ShareSessionView(viewModel: DefaultShareSessionViewModel(session: session, apiClient: ShareSessionApi(), exitRoute: { result in
                                        showShareModal.toggle()
                                        if result == .fileShared {
                                            isShowingEmailSentAlert = true
                                        }
                                    }))
                                }
                            }
                        EmptyView()
                            .sheet(isPresented: $showDeleteModal) {
                                DeleteView(viewModel: DefaultDeleteSessionViewModel(session: session),
                                           deleteModal: $showDeleteModal)
                            }
                        EmptyView()
                            .sheet(isPresented: $showEditView) {
                                editViewSheet
                            }
                        EmptyView()
                            .sheet(isPresented: $showAddNoteModal) {
                                AddNoteView(viewModel: AddNoteViewModel(sessionUUID: session.uuid, withLocation: !session.locationless, exitRoute: { showAddNoteModal.toggle() }))
                            }
                        EmptyView()
                            .sheet(isPresented: $showThresholdAlertModal) {
                                thresholdAlertSheet
                            }
                    }
                )
        }
    }
    
    @ViewBuilder
    private var editViewSheet: some View {
        if session.locationless {
            let vm = EditLocationlessSessionViewModel(sessionUUID: session.uuid, sessionName: session.name ?? "", sessionTags: session.tags ?? "")
            EditView(viewModel: vm)
        } else {
            let vm = EditSessionViewModel(sessionUUID: session.uuid, sessionName: session.name ?? "", sessionTags: session.tags ?? "", sessionSynced: session.urlLocation != nil)
            EditView(viewModel: vm)
        }
    }
}

private extension SessionHeaderView {
    var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                SessionTimeView(session: session)
                    .font(Fonts.moderateRegularHeading4)
                    .foregroundColor(Color.aircastingTimeGray)
                Spacer()
                isMenuNeeded ? actionsMenu : nil
            }
            nameLabelAndExpandButton
        }
        .alert(
            InAppAlerts.finishSessionAlert(
                sessionName: session.name,
                action: { self.finishSessionAlertAction() }
            ),
            $isShowingFinishSessionAlert
        )
        .alert(InAppAlerts.shareFileRequestSent(), $isShowingEmailSentAlert)
        .sheet(isPresented: Binding(
            get: { syncAndFinishViewModel != nil },
            set: { newValue in if !newValue { syncAndFinishViewModel = nil } }
        )) {
            if let vm = syncAndFinishViewModel {
                SyncAndFinishV2SessionDialog(viewModel: vm)
            }
        }
        .foregroundColor(.aircastingGray)
    }
    
    var nameLabelAndExpandButton: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(session.name ?? "")
                    .font(Fonts.moderateMediumHeading1)
                Spacer()
                if isExpandButtonNeeded {
                    Button(action: {
                        action()
                    }) {
                        Image(systemName: chevronIndicator)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                    }
                }
            }
            
            if isSensorTypeNeeded {
                sensorType
                    .font(Fonts.moderateRegularHeading4)
            }
        }
        .foregroundColor(.darkBlue)
    }
    
    var sensorType: some View {
        let allStreams = session.allStreams
        return SessionTypeIndicator(sessionType: session.type, streamSensorNames: allStreams.compactMap(\.sensorPackageName))
    }

    var actionsMenu: some View {
        Menu {
            session.isActive ? actionsMenuStopButton : nil
            session.editable ? actionsMenuEditButton : nil
            session.shareable ? actionsMenuShareButton : nil
            session.deletable ? actionsMenuDeleteButton : nil
            session.isFixed && featureFlagsViewModel.enabledFeatures.contains(.thresholdAlerts) ? actionsMenuThresholdAlertButton : nil
            if checkStandaloneActionAvaibility() {
                actionsMenuMobileEnterStandaloneMode
            }
            if session.isActive && featureFlagsViewModel.enabledFeatures.contains(.notes) {
                actionsMenuNoteButton
            }
        } label: {
            ZStack(alignment: .trailing) {
                EditButtonView()
                Rectangle()
                    .frame(width: 50, height: 35, alignment: .trailing)
                    .opacity(0.0001)
            }
        }
    }
    
    var actionsMenuStopButton: some View {
        Button {
            isShowingFinishSessionAlert = true
        } label: {
            Label(Strings.SessionHeaderView.stopRecordingButton, systemImage: "stop.circle")
        }
    }
    
    var actionsMenuMobileEnterStandaloneMode: some View {
        Button {
            standaloneModeController.moveActiveSessionToStandaloneMode()
        } label: {
            Label(title: { Text(Strings.SessionHeaderView.enterStandaloneModeButton) }, icon: { Image("standalone-icon").renderingMode(.template) })
                .foregroundColor(colorScheme == .light ? .black : .aircastingGray)
        }
    }
    
    var actionsMenuRepeatButton: some View {
        Button {
            // action here
        } label: {
            Label("resume", systemImage: "repeat")
        }
    }
    
    var actionsMenuEditButton: some View {
        Button {
            showEditView = true
        } label: {
            Label(Strings.SessionHeaderView.editButton, systemImage: "pencil")
        }
    }
    
    var actionsMenuShareButton: some View {
        Button {
            showShareModal = true
        } label: {
            Label(Strings.SessionHeaderView.shareButton, systemImage: "square.and.arrow.up")
        }
    }
    
    var actionsMenuDeleteButton: some View {
        Button {
            showDeleteModal = true
        } label: {
            Label(Strings.SessionHeaderView.deleteButton, systemImage: "xmark.circle")
        }
    }
    
    var actionsMenuNoteButton: some View {
        Button {
            showAddNoteModal.toggle()
        } label: {
            Label(Strings.SessionHeaderView.addNoteButton, systemImage: "square.and.pencil")
        }
    }
    
    var actionsMenuThresholdAlertButton: some View {
        Button {
            showThresholdAlertModal.toggle()
        } label: {
            Label(Strings.SessionHeaderView.thresholdAlertsButton, systemImage: "exclamationmark.triangle")
        }
    }
    
    var thresholdAlertSheet: some View {
        ThresholdAlertSheet(session: session, isActive: $showThresholdAlertModal)
    }
    
    private func finishSessionAlertAction() {
        // Phase 6: re-evaluate at confirm-time (not at button-tap time) whether
        // the V2 device has unsynced storage or is mid-drain. If so, chain
        // the SyncAndFinish dialog instead of stopping immediately.
        if let dialogVM = makeSyncAndFinishViewModelIfNeeded() {
            syncAndFinishViewModel = dialogVM
            return
        }
        performStopSession()
    }

    private func performStopSession() {
        let sessionStopper = Resolver.resolve(SessionStoppable.self, args: self.session)
        do {
            try sessionStopper.stopSession()
            selectedSection.mobileSessionWasFinished = true
        } catch {
            Log.info("error when stpoing session - \(error)")
        }
    }

    private func makeSyncAndFinishViewModelIfNeeded() -> SyncAndFinishV2SessionViewModel? {
        let activeProvider = Resolver.resolve(ActiveMobileSessionProvidingService.self)
        guard let active = activeProvider.activeSession,
              active.session.uuid == session.uuid,
              active.device.firmwareVersion == .v2 else { return nil }
        let configurator = Resolver.resolve(AirBeamMiniV2Configurator.self, args: active.device)
        let hasSavedMeasurements: Bool
        if case .hasSavedSession(_, _, let stored, _) = configurator.lastStatus {
            hasSavedMeasurements = stored
        } else {
            hasSavedMeasurements = false
        }
        guard hasSavedMeasurements || configurator.isActiveSyncDraining else { return nil }
        return SyncAndFinishV2SessionViewModel(
            configurator: configurator,
            onFinish: { [self] _ in
                DispatchQueue.main.async {
                    self.syncAndFinishViewModel = nil
                    self.performStopSession()
                }
            }
        )
    }
}

private extension SessionHeaderView {
    func checkStandaloneActionAvaibility() -> Bool {
        guard let devType = session.deviceType else { return false }
        return devType == .AIRBEAM &&
        session.deviceFirmwareVersion != .v2 &&
        session.isActive && featureFlagsViewModel.enabledFeatures.contains(.standaloneMode)
    }
}
