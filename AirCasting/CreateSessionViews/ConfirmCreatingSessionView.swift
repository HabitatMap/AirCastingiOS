//
//  ConfirmCreatingSession.swift
//  AirCasting
//
//  Created by Lunar on 22/02/2021.
//

import AirCastingStyling
import CoreLocation
import SwiftUI
import Resolver

struct ConfirmCreatingSessionView: View {
    @State private var isActive: Bool = false
    @State private var error: NSError? {
        didSet {
            isPresentingAlert = error != nil
        }
    }
    @State private var isPresentingAlert: Bool = false
    /// Phase 6: V2 sync-before-new-session dialog presented on Start Recording
    /// tap when the configured device still holds a previous session's data.
    /// Lives here (not in ConnectingAB) because the user can still back out
    /// of the new-session flow up until this screen — running the dialog
    /// earlier would prompt them about a sync they may not actually commit
    /// to. Once Start Recording is tapped, the next thing that fires is
    /// `NewSessionConfig 0x13` which silently overwrites the device-side
    /// session — the dialog must precede it.
    @State private var pendingSyncDialog: SyncBeforeNewV2SessionViewModel? = nil
    @State private var pendingSessionCreator: SessionCreator? = nil
    @EnvironmentObject var selectedSection: SelectedSection
    @EnvironmentObject private var sessionContext: CreateSessionContext
    @Injected private var locationTracker: LocationTracker
    @Injected private var downloadMeasurementsService: DownloadMeasurementsService
    @EnvironmentObject private var tabSelection: TabBarSelector
    @Binding var creatingSessionFlowContinues: Bool

    let initialLocation: CLLocation?
    var sessionName: String
    private var sessionType: String { (sessionContext.sessionType ?? .fixed).description.lowercased() }
    private var shouldTrackLocation: Bool { sessionContext.sessionType == .mobile && !sessionContext.locationless }
    
    init(creatingSessionFlowContinues: Binding<Bool>, sessionName: String, initialLocation: CLLocation? = nil) {
        _creatingSessionFlowContinues = .init(projectedValue: creatingSessionFlowContinues)
        self.sessionName = sessionName
        self.initialLocation = initialLocation
    }

    var body: some View {
        LoadingView(isShowing: $isActive) {
            contentViewWithAlert
                .onAppear {
                    if shouldTrackLocation {
                        // We need to start tracking location to save the most recent location as the session starting location
                        locationTracker.start()
                    }
                }
                .onDisappear {
                    if shouldTrackLocation {
                        locationTracker.stop()
                    }
                }
                .sheet(isPresented: Binding(
                    get: { pendingSyncDialog != nil },
                    set: { newValue in if !newValue { pendingSyncDialog = nil } }
                )) {
                    if let dialogVM = pendingSyncDialog {
                        SyncBeforeNewV2SessionDialog(viewModel: dialogVM)
                    }
                }
        }
        .background(Color.aircastingBackground.ignoresSafeArea())
    }

    private var contentViewWithAlert: some View {
        contentView.alert(isPresented: $isPresentingAlert) {
            Alert(title: Text(Strings.ConfirmCreatingSessionView.alertTitle),
                  message: Text(error?.localizedDescription ?? Strings.ConfirmCreatingSessionView.alertMessage),
                  dismissButton: .default(Text(Strings.Commons.gotIt), action: { error = nil
            }))
        }
    }

    private var defaultDescriptionText: Text {
        let text = String(format: Strings.ConfirmCreatingSessionView.contentViewText, arguments: [sessionType, sessionName])
        return StringCustomizer.customizeString(text,
                                                using: [sessionType, sessionName],
                                                fontWeight: .bold,
                                                color: .accentColor,
                                                font: Fonts.muliRegularHeading3,
                                                standardFont: Fonts.muliRegularHeading3)
    }

    var dot: some View {
        Capsule()
            .fill(Color.accentColor)
            .frame(width: 15, height: 15)
    }

    private var descriptionTextFixed: some View {
        defaultDescriptionText
        + Text((sessionContext.isIndoor!) ? "" : Strings.ConfirmCreatingSessionView.contentViewTextEnd)
    }

    private var descriptionTextMobile: some View {
        defaultDescriptionText
        + Text(Strings.ConfirmCreatingSessionView.contentViewTextEndMobile)
    }

    @ViewBuilder private var contentView: some View {
        if let sessionCreator = setSessioonCreator() {
            VStack(alignment: .leading, spacing: 40) {
                ProgressView(value: 0.95)
                Text(Strings.ConfirmCreatingSessionView.contentViewTitle)
                    .font(Fonts.muliHeavyTitle1)
                    .foregroundColor(.darkBlue)
                VStack(alignment: .leading, spacing: 15) {
                    if sessionContext.sessionType == .fixed {
                        descriptionTextFixed
                    } else if !sessionContext.locationless {
                        descriptionTextMobile
                    } else {
                        defaultDescriptionText
                    }
                }
                .font(Fonts.muliRegularHeading3)
                .foregroundColor(Color.aircastingGray)
                .lineSpacing(9.0)
                ZStack {
                    if sessionContext.sessionType == .mobile {
                        if !sessionContext.locationless {
                            _MapView(path: [],
                                     type: .normal,
                                     trackingStyle: .user,
                                     userIndicatorStyle: .standard,
                                     locationTracker: MapLocationTrackerAdapter(locationTracker),
                                     markers: [])
                        }
                    } else if !(sessionContext.isIndoor ?? false) {
                        _MapView(path: [],
                                 type: .normal,
                                 trackingStyle: .none,
                                 userIndicatorStyle: .none,
                                 locationTracker: ConstantTracker(location: initialLocation!),
                                 markers: [])
                        .disabled(true)
                        // It needs to be disabled to prevent user interaction (swiping map) because it is only conformation screen
                        dot
                    }
                }
                Button(action: {
                    handleStartRecordingTap(sessionCreator: sessionCreator)
                }, label: {
                    Text(Strings.ConfirmCreatingSessionView.startRecording)
                        .font(Fonts.muliBoldHeading1)
                })
                .buttonStyle(BlueButtonStyle())
                .disabled(isActive)
            }
            .padding()
        }
    }
}

extension ConfirmCreatingSessionView {

    /// Phase 6: gate "Start Recording" on the V2 sync-before-new dialog. If the
    /// configured device is V2 and is currently holding a previous session
    /// (HasSavedSession, or Running under a different session UUID than the
    /// one we're about to create), surface Sync/Discard/Cancel first. Only
    /// after the user resolves the dialog do we kick off `createSession`
    /// (which fires `NewSessionConfig 0x13` and silently overwrites the
    /// device's session state).
    func handleStartRecordingTap(sessionCreator: SessionCreator) {
        let device = sessionContext.device
        if let device = device,
           device.firmwareVersion == .v2,
           let dialogVM = makeSyncBeforeNewDialog(for: device, sessionCreator: sessionCreator) {
            pendingSessionCreator = sessionCreator
            pendingSyncDialog = dialogVM
            return
        }
        startCreatingSession(sessionCreator: sessionCreator)
    }

    private func startCreatingSession(sessionCreator: SessionCreator) {
        getAndSaveStartingLocation()
        isActive = true
        createSession(sessionCreator: sessionCreator)
    }

    private func makeSyncBeforeNewDialog(for device: any BluetoothDevice,
                                         sessionCreator: SessionCreator) -> SyncBeforeNewV2SessionViewModel? {
        let configurator = Resolver.resolve(AirBeamMiniV2Configurator.self, args: device)
        let newSessionUUID = sessionContext.sessionUUID.flatMap { UUID(uuidString: $0.rawValue) }
        let shouldPrompt: Bool
        switch configurator.lastStatus {
        case .hasSavedSession(_, _, let hasMeasurements, _):
            // After a successful manual BLE sync, firmware may keep the saved-session
            // shell with hasMeasurements=false / fileSize=0 instead of fully
            // returning to idle. Don't pester the user about syncing what we
            // just drained — `configureMobileSession` still sends
            // DiscardSession (0x11) on any hasSavedSession state to clean up
            // the device before NewSessionConfig.
            shouldPrompt = hasMeasurements
        case .running(_, let deviceUUID):
            // Device is recording under a different session UUID than the new
            // one — that previous session must be drained or discarded
            // before NewSessionConfig overwrites it.
            shouldPrompt = (deviceUUID != newSessionUUID)
        case .idle, .readyToSync, .none:
            shouldPrompt = false
        }
        guard shouldPrompt else {
            Log.info("V2 Confirm: lastStatus=\(String(describing: configurator.lastStatus)) newUUID=\(String(describing: newSessionUUID)) — skipping SyncBeforeNew dialog")
            return nil
        }
        Log.info("V2 Confirm: previous session detected (\(String(describing: configurator.lastStatus))) — presenting SyncBeforeNew dialog")
        return SyncBeforeNewV2SessionViewModel(
            configurator: configurator,
            onResolved: { outcome in
                DispatchQueue.main.async {
                    self.pendingSyncDialog = nil
                    switch outcome {
                    case .proceedWithNewSession:
                        self.startCreatingSession(sessionCreator: sessionCreator)
                    case .cancel:
                        // User cancelled — leave them on the confirm screen so
                        // they can re-tap or back out of the new-session flow.
                        self.pendingSessionCreator = nil
                    }
                }
            }
        )
    }

    func createSession(sessionCreator: SessionCreator) {
        sessionCreator.createSession(sessionContext) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.creatingSessionFlowContinues = false
                    if sessionContext.sessionType == .mobile {
                        selectedSection.section = .mobileActive
                    } else {
                        selectedSection.section = .following
                        downloadMeasurementsService.triggerQuickRefresh()
                    }
                    tabSelection.update(to: .dashboard)

                case .failure(let error):
                    self.error = error as NSError
                    Log.warning("Failed to create session \(error)")
                }
                isActive = false
            }
        }
    }

    func getAndSaveStartingLocation() {
        #if targetEnvironment(simulator)
        let krakowLat = 50.049683
        let krakowLong = 19.944544
        sessionContext.saveCurrentLocation(lat: krakowLat, log: krakowLong)
        return
        #endif
        if sessionContext.sessionType == .fixed || sessionContext.locationless {
            if sessionContext.isIndoor! || sessionContext.locationless {
                sessionContext.saveCurrentLocation(lat: 200, log: 200)
            }
        } else {
            guard let lat = (locationTracker.location.value?.coordinate.latitude),
                  let lon = (locationTracker.location.value?.coordinate.longitude) else { return }
            sessionContext.saveCurrentLocation(lat: lat, log: lon)
        }
    }
    func setSessioonCreator() -> SessionCreator? {
        let isWifi: Bool = (sessionContext.wifiSSID != nil && sessionContext.wifiSSID != nil)
        if sessionContext.sessionType == .fixed && isWifi {
            return AirBeamFixedWifiSessionCreator()
        } else if sessionContext.sessionType == .fixed && !isWifi {
            return AirBeamCellularSessionCreator()
        } else if sessionContext.sessionType == .mobile && sessionContext.deviceType == .MIC {
            return MicrophoneSessionCreator()
        } else if sessionContext.sessionType == .mobile {
            return MobilePeripheralSessionCreator()
        } else {
            return nil
            Log.info("Can't set the session creator storage")
        }
    }

}
