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
    @Binding var isCollapsed: Bool
    @State var chevronIndicator = "chevron.down"
    @InjectedObject private var bluetoothManager: BluetoothManager
    @EnvironmentObject var selectedSection: SelectedSection
    @ObservedObject var session: SessionEntity
    @State private var showingNoConnectionAlert = false
    @State private var alert: AlertInfo?
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    @State var showDeleteModal = false
    @State var showAddNoteModal = false
    @State var showShareModal = false
    @State var showEditView = false
    @State var detectEmailSent = false
    @State var showThresholdAlertModal = false
    
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
                                                    alert = InAppAlerts.shareFileRequestSent()
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
                                            alert = InAppAlerts.shareFileRequestSent()
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
            let vm = EditSessionViewModel(sessionUUID: session.uuid)
            EditView(viewModel: vm)
        }
    }
}

private extension SessionHeaderView {
    var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                dateAndTime
                    .font(Fonts.moderateRegularHeading4)
                    .foregroundColor(Color.aircastingTimeGray)
                Spacer()
                (isMenuNeeded && selectedSection.section != .following) ? actionsMenu : nil
            }
            nameLabelAndExpandButton
        }
        .alert(item: $alert, content: { $0.makeAlert() })
        .onChange(of: isCollapsed, perform: { value in
            isCollapsed ? (chevronIndicator = "chevron.down") :  (chevronIndicator = "chevron.up")
        })
        .foregroundColor(.aircastingGray)
    }

    var dateAndTime: some View {
        adaptTimeAndDate()
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
            // As long as we get session.deviceType = nil we should handle somehow showing those devices which were used to record
            // [|(-)   (-)|]    |-------------------|
            //  |   ___   |  -- | You, do something |
            //  |_________|     |-------------------|
            // so the idea at leat for now is this below
#warning("Fix - Handle session.deviceType (for now it is always nill)")
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
            session.isFixed ? actionsMenuThresholdAlertButton : nil
            if session.deviceType == .AIRBEAM3 && session.isActive && featureFlagsViewModel.enabledFeatures.contains(.standaloneMode) {
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
            alert = InAppAlerts.finishSessionAlert(sessionName: session.name, action: {
                self.finishSessionAlertAction()
            })
        } label: {
            Label(Strings.SessionHeaderView.stopRecordingButton, systemImage: "stop.circle")
        }
    }
    
    var actionsMenuMobileEnterStandaloneMode: some View {
        Button {
            bluetoothManager.enterStandaloneMode(sessionUUID: session.uuid)
        } label: {
            Label(Strings.SessionHeaderView.enterStandaloneModeButton, image: "standalone-icon")
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
        ThresholdAlertSheet(viewModel: ThresholdAlertSheetViewModel(session: session, apiClient: ShareSessionApi()), isActive: $showThresholdAlertModal)
    }

    func adaptTimeAndDate() -> Text {
        let formatter: DateIntervalFormatter = DateFormatters.SessionCardView.shared.utcDateIntervalFormatter
        guard let start = session.startTime else { return Text("") }
        let end = session.endTime ?? DateBuilder.getFakeUTCDate()
        
        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
    
    private func finishSessionAlertAction() {
        let sessionStopper = Resolver.resolve(SessionStoppable.self, args: self.session)
        do {
            try sessionStopper.stopSession()
        } catch {
            Log.info("error when stpoing session - \(error)")
        }
    }
}
