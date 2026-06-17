// Created by Lunar on 21/07/2021.
//

import Foundation
import Combine
import Resolver

struct SDSyncProgressViewModel {
    let title: String
    let current: String
    let total: String
}

protocol SDSyncViewModel: ObservableObject {
    var presentNextScreen: Bool { get set }
    var isDownloadingFinished: Bool { get }
    var shouldDismiss: Bool { get set }
    var alert: AlertInfo? { get set }
    var progress: Published<SDSyncProgressViewModel?>.Publisher { get }
    func connectToAirBeamAndSync(_ standaloneSessionToSyncAndFinish: StandaloneSessionToSyncAndFinish)
}

// [RESOLVER] Move this VM init to view afte all dependencies are resolved
class SDSyncViewModelDefault: SDSyncViewModel, ObservableObject {
    var progress: Published<SDSyncProgressViewModel?>.Publisher { $progressValue }

    @Published private var progressValue: SDSyncProgressViewModel?
    @Published var isDownloadingFinished: Bool = false
    @Published var presentNextScreen: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var alert: AlertInfo?

    private let device: any BluetoothDevice
    @Injected private var airBeamConnectionController: AirBeamConnectionController
    @Injected private var btConnectionChecker: BluetoothPeripheralConnectionChecker
    @Injected private var sdSyncController: SDSyncController
    @Injected private var measurementsSaver: MeasurementsSavingService
    @Injected private var sessionFinisher: SessionFinisher
    @Injected private var persistenceController: PersistenceController
    @Injected private var reconnectGuard: SessionManagingReconnectionController
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var v2LocationBackfillCoordinator: V2LocationBackfillCoordinator
    private let sessionContext: CreateSessionContext
    private var v2Orchestrator: V2BleSyncOrchestrator?

    init(sessionContext: CreateSessionContext,
         device: any BluetoothDevice) {
        self.device = device
        self.sessionContext = sessionContext
    }

    func connectToAirBeamAndSync(_ standaloneSessionToSyncAndFinish: StandaloneSessionToSyncAndFinish) {
        // Suppress auto-reconnect for the duration of the SD sync flow: if the
        // user has an active mobile session on this device, `shouldReconnect`
        // would otherwise return true and the reconnect chain would race the
        // SD-sync's own explicit connect/disconnect calls (stale
        // CBCharacteristic pointers → CoreBluetooth malloc abort during clear
        // SD card step). `disconnectAirBeam` releases the suppression on every
        // terminal branch of the flow.
        reconnectGuard.suppressReconnect(deviceUUID: device.uuid)
        self.airBeamConnectionController.connectToAirBeam(device: device) { result in
            Log.info("[SD SYNC] Completed connecting to AB")
            guard result == .success else {
                self.reconnectGuard.releaseReconnect(deviceUUID: self.device.uuid)
                DispatchQueue.main.async {
                    self.presentNextScreen = false
                    self.getConnectionAlert(result)
                }
                return
            }
            // V2 has no SD card — use the BLE manual-sync flow (StartBleSync 0x16)
            // instead of the V1 SDCardAirBeamServices CSV download. Persisted records
            // are saved through `MeasurementsSavingService.saveV2SyncMeasurement`
            // which does not require an active session, so the standalone-finish
            // path works the same as for V1.
            if self.device.firmwareVersion == .v2 {
                self.runV2ManualSync(standaloneSessionToSyncAndFinish)
                return
            }
            self.sdSyncController.syncFromAirbeam(standaloneSessionToSyncAndFinish: standaloneSessionToSyncAndFinish,
                                                  self.device,
                                                  progress: { [weak self] newStatus in
                guard let self = self else { return }
                switch newStatus {
                case .inProgress(let progress):
                    DispatchQueue.main.async {
                        let sessionType = self.stringForSessionType(progress.sessionType)
                        self.progressValue = .init(title: sessionType, current: String(progress.progress.received), total: String(progress.progress.expected))
                    }
                case .finalizing:
                    DispatchQueue.main.async {
                        self.isDownloadingFinished = true
                    }
                }
            }, completion: { [weak self] result in
                Log.info("[SD SYNC] Completed syncing with result: \(result)")
                guard let self = self else { return }
                switch result {
                case .success():
                    guard (try? self.btConnectionChecker.isDeviceConnected(device: self.device)) ?? false else {
                        Log.info("[SD SYNC] Device disconnected. Attempting reconnect")
                        self.reconnectWithAirbeamAndClearCard()
                        return
                    }
                    self.clearSDCard()
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.alert = self.alertForError(error)
                        self.presentNextScreen = false
                    }
                    self.disconnectAirBeam()
                }
            })
        }
    }

    // MARK: - V2 BLE manual sync (Phase 6)

    private func runV2ManualSync(_ standaloneSessionToSyncAndFinish: StandaloneSessionToSyncAndFinish) {
        guard let sessionUUID = standaloneSessionToSyncAndFinish.uuid else {
            Log.error("[SD SYNC V2] Missing standalone session UUID")
            DispatchQueue.main.async {
                self.alert = InAppAlerts.failedSDClearingAlert { self.shouldDismiss = true }
                self.presentNextScreen = false
            }
            self.disconnectAirBeam()
            return
        }
        let configurator = Resolver.resolve(AirBeamMiniV2Configurator.self, args: device)
        configurator.configureSession(uuid: sessionUUID) { [weak self] configureResult in
            guard let self = self else { return }
            switch configureResult {
            case .failure(let error):
                Log.error("[SD SYNC V2] configureSession failed: \(error)")
                DispatchQueue.main.async {
                    self.alert = self.alertForError(.readingDataFailure)
                    self.presentNextScreen = false
                }
                self.disconnectAirBeam()
            case .success:
                // Tag mobile-session status for progress UI parity with the V1 path.
                DispatchQueue.main.async {
                    self.progressValue = .init(title: Strings.SyncingABView.mobile, current: "0", total: "100")
                }
                let orchestrator = configurator.makeManualSyncOrchestrator()
                self.v2Orchestrator = orchestrator
                orchestrator.start(progress: { [weak self] progress in
                    DispatchQueue.main.async {
                        self?.progressValue = .init(title: Strings.SyncingABView.mobile,
                                                     current: String(progress.percent),
                                                     total: "100")
                    }
                }, completion: { [weak self] result in
                    guard let self = self else { return }
                    self.v2Orchestrator = nil
                    switch result {
                    case .success(let records):
                        Log.info("[SD SYNC V2] orchestrator completed with \(records.count) records")
                        self.persistV2Records(records, sessionUUID: sessionUUID)
                        self.finishV2StandaloneSession(uuid: sessionUUID) { finishResult in
                            DispatchQueue.main.async {
                                switch finishResult {
                                case .success:
                                    self.isDownloadingFinished = true
                                    self.presentNextScreen = true
                                case .failure:
                                    self.alert = self.alertForError(.mobileSessionsProcessingFailure)
                                    self.presentNextScreen = false
                                }
                            }
                            DispatchQueue.main.async {
                                standaloneSessionToSyncAndFinish.clearSessionUuid()
                            }
                            // V1 parity: when the user kicks off SD sync while a
                            // mobile session is still active on this device (DB
                            // status RECORDING/DISCONNECTED, not standalone),
                            // `SDCardMobileSessionFinisher` guards on
                            // `isInStandaloneMode` and no-ops — leaving the
                            // session pinned to the mobile-active tab forever.
                            // Explicitly stop the active session here so it
                            // transitions to FINISHED, mirroring the V1
                            // `clearSDCard` ordering. Safe when there's no
                            // matching active session (early return).
                            self.finishActiveSessionIfMatchingDevice()
                            self.disconnectAirBeam()
                        }
                    case .failure(let error):
                        Log.error("[SD SYNC V2] orchestrator failed: \(error)")
                        DispatchQueue.main.async {
                            self.alert = self.alertForError(.readingDataFailure)
                            self.presentNextScreen = false
                        }
                        self.disconnectAirBeam()
                    }
                })
            }
        }
    }

    private func persistV2Records(_ records: [V2SyncRecord], sessionUUID: SessionUUID) {
        let isLocationless = readLocationless(sessionUUID: sessionUUID)
        v2LocationBackfillCoordinator.beginSaveBatch(sessionUUID: sessionUUID)
        defer { v2LocationBackfillCoordinator.endSaveBatch(sessionUUID: sessionUUID) }
        for record in records {
            let streams = V2StreamFactory.makeStreams(pm1: Double(record.pm1),
                                                      pm25: Double(record.pm25))
            let backfill = isLocationless
                ? nil
                : v2LocationBackfillCoordinator.location(for: sessionUUID, at: record.timestamp)
            measurementsSaver.saveV2SyncMeasurement(streams.pm1,
                                                    sessionUUID: sessionUUID,
                                                    time: record.timestamp,
                                                    locationless: isLocationless,
                                                    locationOverride: backfill)
            measurementsSaver.saveV2SyncMeasurement(streams.pm25,
                                                    sessionUUID: sessionUUID,
                                                    time: record.timestamp,
                                                    locationless: isLocationless,
                                                    locationOverride: backfill)
        }
    }

    private func readLocationless(sessionUUID: SessionUUID) -> Bool {
        // Best-effort: missing/inaccessible session falls back to false (let
        // saveV2SyncMeasurement use the phone's last-known fix). Either way the
        // record gets persisted with valid PM values; only location accuracy
        // differs.
        let ctx = persistenceController.editContext
        var result = false
        ctx.performAndWait {
            if let session = try? ctx.existingSession(uuid: sessionUUID) {
                result = session.locationless
            }
        }
        return result
    }

    private func finishV2StandaloneSession(uuid: SessionUUID,
                                           completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.sessionFinisher(uuid: uuid)
                // Standalone-finish bypasses `stopRecordingSession`, so the
                // backfill sampler + persisted buffer would otherwise keep
                // accumulating writes for a session that is already FINISHED.
                // Tell the coordinator the session is done so it stops the
                // sampler and (refcount-permitting) wipes the buffer.
                self.v2LocationBackfillCoordinator.stopSampling(sessionUUID: uuid)
                completion(.success(()))
            } catch {
                Log.error("[SD SYNC V2] finishStandaloneSession failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    private func clearSDCard() {
        self.sdSyncController.clearSDCard(self.device) { result in
            DispatchQueue.main.async {
                self.presentNextScreen = true
                if !result {
                    Log.error("[SD SYNC] Couldn't clear SD card after sync")
                }
            }
            // If the user kicked off SD sync while a mobile recording session
            // was still active on this device, the wizard is logically an
            // end-of-session intent — stop the active session first so the
            // subsequent BLE disconnect doesn't trigger the auto-reconnect
            // chain (`shouldReconnect == true` while `activeSession` matches)
            // and silently resume recording behind the SDSyncCompleteView.
            self.finishActiveSessionIfMatchingDevice()
            self.disconnectAirBeam()
        }
    }

    private func finishActiveSessionIfMatchingDevice() {
        guard let active = activeSessionProvider.activeSession,
              active.device.uuid == device.uuid else { return }
        let stopper = Resolver.resolve(SessionStoppable.self, args: active.session)
        do {
            try stopper.stopSession()
            Log.info("[SD SYNC] Stopped active session \(active.session.uuid) post-sync")
        } catch {
            Log.error("[SD SYNC] Failed to stop active session post-sync: \(error)")
        }
    }
    
    private func reconnectWithAirbeamAndClearCard() {
        airBeamConnectionController.connectToAirBeam(device: device) { [weak self] result in
            guard let self = self else { return }
            guard result == .success else {
                Log.info("[SD SYNC] Reconnecting failed")
                self.reconnectGuard.releaseReconnect(deviceUUID: self.device.uuid)
                DispatchQueue.main.async {
                    self.presentNextScreen = false
                    self.alert = InAppAlerts.failedSDClearingAlert {
                        self.shouldDismiss = true
                    }
                }
                return
            }
            self.clearSDCard()
        }
    }

    private func disconnectAirBeam() {
        // Releasing here covers every SD-sync terminal branch since each one
        // routes through this helper. After this call the recording-session
        // auto-reconnect chain is allowed to fire again on the next
        // didDisconnect event.
        reconnectGuard.releaseReconnect(deviceUUID: device.uuid)
        airBeamConnectionController.disconnectAirBeam(device: device)
    }
    
    private func alertForError(_ error: SDSyncError) -> AlertInfo {
        switch error {
        case .unidetifiableDevice:
            return InAppAlerts.connectionTimeoutAlert {
                self.shouldDismiss = true
            }
        case .filesCorrupted:
            return InAppAlerts.sdSyncFilesCorruptedAlert {
                self.shouldDismiss = true
            }
        case .readingDataFailure:
            return InAppAlerts.sdSyncReadingDataAlert {
                self.shouldDismiss = true
            }
        case .fixedSessionsProcessingFailure:
            return InAppAlerts.sdSyncFixedFailAlert {
                self.shouldDismiss = true
            }
        case .mobileSessionsProcessingFailure:
            return InAppAlerts.sdSyncMobileFailAlert {
                self.shouldDismiss = true
            }
        }
    }
    
    private func getConnectionAlert(_ result: AirBeamServicesConnectionResult) {
        switch result {
        case .timeout:
            self.alert = InAppAlerts.connectionTimeoutAlert {
                self.shouldDismiss = true
            }
        case .deviceBusy:
            self.alert = InAppAlerts.bluetoothSessionAlreadyRecordingAlert {
                self.shouldDismiss = true
            }
        case .success:
            break
        case .incompatibleDevice:
            self.alert = InAppAlerts.incompatibleDevice {
                self.shouldDismiss = true
            }
        case .unknown(_):
            self.alert = InAppAlerts.genericErrorAlert {
                self.shouldDismiss = true
            }
        }
    }

    private func stringForSessionType(_ sessionType: SDCardSessionType) -> String {
        switch sessionType {
        case .cellular: return Strings.SyncingABView.cellular
        case .fixed: return Strings.SyncingABView.fixed
        case .mobile: return Strings.SyncingABView.mobile
        }
    }
}
