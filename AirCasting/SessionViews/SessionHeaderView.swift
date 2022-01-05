//
//  SessionHeader.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//
import AirCastingStyling
import SwiftUI

struct SessionHeaderView: View {
    let action: () -> Void
    let isExpandButtonNeeded: Bool
    var isSensorTypeNeeded: Bool = true
    var isMenuNeeded = true
    @Binding var isCollapsed: Bool
    @State var chevronIndicator = "chevron.down"
    @EnvironmentObject var networkChecker: NetworkChecker
    @EnvironmentObject var bluetoothManager: BluetoothManager
    let urlProvider: BaseURLProvider
    @EnvironmentObject var selectedSection: SelectSection
    @ObservedObject var session: SessionEntity
    @State private var showingNoConnectionAlert = false
    @State private var alert: AlertInfo?
    let sessionStopperFactory: SessionStoppableFactory
    @StateObject private var featureFlagsViewModel = FeatureFlagsViewModel.shared
    @State var showDeleteModal = false
    @State var showAddNoteModal = false
    @State var showShareModal = false
    @State var showEditView = false
    let measurementStreamStorage: MeasurementStreamStorage
    let sessionSynchronizer: SessionSynchronizer
    @EnvironmentObject var authorization: UserAuthenticationSession
    
    var body: some View {
        if #available(iOS 15, *) {
            sessionHeader
                .sheet(isPresented: $showDeleteModal) {
                    DeleteView(viewModel: DefaultDeleteSessionViewModel(session: session, measurementStreamStorage: measurementStreamStorage, streamRemover: DefaultSessionUpdateService(authorization: authorization, urlProvider: urlProvider), sessionSynchronizer: sessionSynchronizer), deleteModal: $showDeleteModal)
                }
                .sheet(isPresented: $showShareModal) {
                    ShareSessionView(viewModel: DefaultShareSessionViewModel(session: session, apiClient: ShareSessionApi(urlProvider: urlProvider), exitRoute: { sharedEmail in
                        showShareModal.toggle()
                        if sharedEmail == true {
                            alert = InAppAlerts.shareFileRequestSent()
                        }
                    }))
                }
                .sheet(isPresented: $showEditView) {
                    editViewSheet
                }
                .sheet(isPresented: $showAddNoteModal) {
                    AddNoteView(viewModel: AddNoteViewModelDefault(exitRoute: { showAddNoteModal.toggle() }))
                }
        } else {
            sessionHeader
                .background(
                    Group {
                        EmptyView()
                            .sheet(isPresented: $showDeleteModal) {
                                DeleteView(viewModel: DefaultDeleteSessionViewModel(session: session, measurementStreamStorage: measurementStreamStorage, streamRemover: DefaultSessionUpdateService(authorization: authorization, urlProvider: urlProvider), sessionSynchronizer: sessionSynchronizer), deleteModal: $showDeleteModal)
                            }
                        EmptyView()
                            .sheet(isPresented: $showShareModal) {
                                ShareSessionView(viewModel: DefaultShareSessionViewModel(session: session, apiClient: ShareSessionApi(urlProvider: urlProvider), exitRoute: { sharedEmail in
                                    showShareModal.toggle()
                                    if sharedEmail == true {
                                        alert = InAppAlerts.shareFileRequestSent()
                                    }
                                }))
                            }
                        EmptyView()
                            .sheet(isPresented: $showDeleteModal) {
                                DeleteView(viewModel: DefaultDeleteSessionViewModel(session: session,
                                                                                    measurementStreamStorage: measurementStreamStorage,
                                                                                    streamRemover: DefaultSessionUpdateService(authorization: authorization,
                                                                                                                               urlProvider: urlProvider),
                                                                                    sessionSynchronizer: sessionSynchronizer),
                                           deleteModal: $showDeleteModal)
                            }
                        EmptyView()
                            .sheet(isPresented: $showEditView) {
                                editViewSheet
                            }
                        EmptyView()
                            .sheet(isPresented: $showAddNoteModal) {
                                AddNoteView(viewModel: AddNoteViewModelDefault(exitRoute: { showAddNoteModal.toggle() }))
                            }
                    }
                )
        }
    }
    
    @ViewBuilder
    private var editViewSheet: some View {
        let vm = EditSessionViewModel(measurementStreamStorage: measurementStreamStorage,
                                      sessionSynchronizer: sessionSynchronizer,
                                      sessionUpdateService: DefaultSessionUpdateService(authorization: authorization,
                                                                                        urlProvider: urlProvider),
                                      sessionUUID: session.uuid)
        EditView(viewModel: vm)
    }
}

private extension SessionHeaderView {
    var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                dateAndTime
                    .foregroundColor(Color.aircastingTimeGray)
                Spacer()
                (isMenuNeeded && selectedSection.selectedSection != .following) ? actionsMenu : nil
            }
            nameLabelAndExpandButton
        }
        .alert(item: $alert, content: { $0.makeAlert() })
        .onChange(of: isCollapsed, perform: { value in
            isCollapsed ? (chevronIndicator = "chevron.down") :  (chevronIndicator = "chevron.up")
        })
        .font(Fonts.regularHeading4)
        .foregroundColor(.aircastingGray)
    }

    var dateAndTime: some View {
        adaptTimeAndDate()
    }
    
    var nameLabelAndExpandButton: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(session.name ?? "")
                    .font(Fonts.regularHeading1)
                Spacer()
                if isExpandButtonNeeded {
                    Button(action: {
                        action()
                    }) {
                        Image(systemName: chevronIndicator)
                            .renderingMode(.original)
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
                    .font(Fonts.regularHeading4)
            }
        }
        .foregroundColor(.darkBlue)
    }
    
    var sensorType: some View {
        var stream = [String]()
        var text = ""
        guard session.allStreams != nil else { return Text("") }
        session.allStreams!.forEach { session in
            if var name = session.sensorPackageName {
                componentsSeparation(name: &name)
                (name == "Builtin") ? (name = "Phone mic") : (name = name)
                !stream.contains(name) ? stream.append(name) : nil
            }
        }
        text = stream.joined(separator: ", ")
        return Text("\(session.type!.description) : \(text)")
    }
    
    func componentsSeparation(name: inout String) {
        // separation is used to nicely handle the case where sensor could be
        // AirBeam2-xxxx or AirBeam2:xxx
        if name.contains(":") {
            name = name.components(separatedBy: ":").first!
        } else {
            name = name.components(separatedBy: "-").first!
        }
    }

    var actionsMenu: some View {
        Menu {
            session.isActive ? actionsMenuStopButton : nil
            session.deletable ? actionsMenuDeleteButton : nil
            session.shareable ? actionsMenuShareButton : nil
            session.isEditable ? actionsMenuEditButton : nil
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
                self.finishSessionAlertAction(sessionStopper: self.sessionStopperFactory.getSessionStopper(for: self.session))
            })
        } label: {
            Label(Strings.SessionHeaderView.stopRecordingButton, systemImage: "stop.circle")
        }
    }
    
    var actionsMenuMobileEnterStandaloneMode: some View {
        Button {
            bluetoothManager.enterStandaloneMode(sessionUUID: session.uuid)
        } label: {
            Label(Strings.SessionHeaderView.enterStandaloneModeButton, systemImage: "xmark.circle")
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

    func adaptTimeAndDate() -> Text {
        let formatter = DateFormatters.SessionCartView.utcDateIntervalFormatter
        
        guard let start = session.startTime else { return Text("") }
        let end = session.endTime ?? Date().currentUTCTimeZoneDate
        
        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
    
    private func finishSessionAlertAction(sessionStopper: SessionStoppable) {
        do {
            try sessionStopper.stopSession()
        } catch {
            Log.info("error when stpoing session - \(error)")
        }
    }
}

#if DEBUG
struct SessionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SessionHeaderView(action: {},
                          isExpandButtonNeeded: true,
                          isCollapsed: .constant(true),
                          urlProvider: DummyURLProvider(),
                          session: SessionEntity.mock,
                          sessionStopperFactory: SessionStoppableFactoryDummy(),
                          measurementStreamStorage: PreviewMeasurementStreamStorage(),
                          sessionSynchronizer: DummySessionSynchronizer())
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
}
#endif
