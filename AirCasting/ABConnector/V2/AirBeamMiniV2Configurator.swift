// Created by Lunar on 30/04/2026.
//

import Foundation
import CoreLocation
import CoreBluetooth
import Resolver

final class AirBeamMiniV2Configurator: AirBeamConfigurator {
    enum AirBeamMiniV2ConfiguratorError: Swift.Error, LocalizedError {
        case notImplemented
        case statusDecodeFailed
        case statusTimeout
        case missingCharacteristic
        case missingSessionUUID
        case unexpectedStatusForResume
        case sessionUUIDMismatch

        var errorDescription: String? {
            switch self {
            case .notImplemented: return "AirBeam Mini V2 path not implemented for this flow."
            case .statusDecodeFailed: return "Could not understand AirBeam Mini V2 status."
            case .statusTimeout: return "AirBeam Mini V2 did not respond in time."
            case .missingCharacteristic: return "AirBeam Mini V2 BLE service is incomplete."
            case .missingSessionUUID: return "Could not start AirBeam Mini V2 session: missing session UUID."
            case .unexpectedStatusForResume: return "AirBeam Mini V2 is in an unexpected state for resume."
            case .sessionUUIDMismatch: return "AirBeam Mini V2 stored session does not match the active one."
            }
        }
    }

    @Injected private var btCommunicator: BluetoothCommunicator
    @Injected private var btPeripheral: BluetoothPeripheralConfigurator
    @Injected private var measurementsSaver: MeasurementsSavingService
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var v2LocationBackfillCoordinator: V2LocationBackfillCoordinator

    private let device: any BluetoothDevice
    private let queue = DispatchQueue(label: "ab.v2.configurator")
    /// Key used to detect "am I already on `queue`?" so `teardown` (and any
    /// other `queue.sync` site reachable from a dispatcher completion fired
    /// inside `queue.async`) can run inline instead of deadlocking on the
    /// serial queue. See `runOnQueueSync(...)`.
    private static let queueIdentityKey = DispatchSpecificKey<ObjectIdentifier>()
    private let queueIdentity = ObjectIdentifier(NSObject())
    private let dispatcher = V2ResponseDispatcher()

    private var subscriptionTokens: [AnyHashable] = []
    private var responseSubscribed = false
    private var measurementSubscribed = false
    private(set) var lastStatus: V2BinaryProtocol.Status?
    private(set) var sensorInfo: String?
    private(set) var configuredSessionUUID: SessionUUID?

    private var statusAwaiter: ((Result<V2BinaryProtocol.Status, Error>) -> Void)?
    private var fallbackReadWorkItem: DispatchWorkItem?

    private var setTimeTimer: Timer?
    private var mobileSessionActive: Bool = false

    // Active-sync drain detection (Phase 3): Running Status doesn't carry a
    // has_measurements byte, so we infer drain via "Sync indication seen in the
    // last 3 s" and surface it as an observable property.
    private var syncDrainResetWorkItem: DispatchWorkItem?
    private var isActiveSyncDrainingStorage: Bool = false
    private static let syncDrainIdleTimeoutSeconds: TimeInterval = 3.0
    var isActiveSyncDraining: Bool {
        var value = false
        runOnQueueSync { value = isActiveSyncDrainingStorage }
        return value
    }

    /// When non-nil, sync-characteristic chunks are routed to this closure instead
    /// of the default reconnect-time DB save path. Phase 6 manual sync orchestrator
    /// installs an interceptor while a `StartBleSync (0x16)` is in flight.
    var syncChunkInterceptor: ((Data) -> Void)? {
        get {
            var value: ((Data) -> Void)?
            runOnQueueSync { value = _syncChunkInterceptor }
            return value
        }
        set {
            runOnQueueSync { _syncChunkInterceptor = newValue }
        }
    }
    private var _syncChunkInterceptor: ((Data) -> Void)?

    /// Active manual BLE sync (`StartBleSync 0x16`) orchestrator. While set,
    /// the configurator routes status / sync / response events to the
    /// orchestrator instead of the default reconnect-time + dispatcher paths.
    /// Phase 6.
    private var activeManualSync: V2BleSyncOrchestrator?

    init(device: any BluetoothDevice) {
        self.device = device
        queue.setSpecific(key: Self.queueIdentityKey, value: queueIdentity)
    }

    /// Runs `work` synchronously on `queue`. If already on `queue` (re-entrant
    /// call from a dispatcher handler that fired inside an earlier
    /// `queue.async`), executes inline to avoid the GCD serial-queue deadlock.
    private func runOnQueueSync(_ work: () -> Void) {
        if DispatchQueue.getSpecific(key: Self.queueIdentityKey) == queueIdentity {
            work()
        } else {
            queue.sync { work() }
        }
    }

    deinit {
        teardown()
    }

    /// Phase 1 entry point: subscribe to all 4 notifying V2 chars, settle 300ms, await first Status.
    func subscribeAndAwaitStatus(timeout: TimeInterval = 5.0,
                                 completion: @escaping (Result<V2BinaryProtocol.Status, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let cached = self.lastStatus {
                completion(.success(cached))
                return
            }
            self.statusAwaiter = completion
            self.ensureSubscriptions()

            DispatchQueue.main.asyncAfter(deadline: .now() + V2BinaryProtocol.settleDelaySeconds) { [weak self] in
                self?.scheduleStatusFallbackRead()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                self?.queue.async {
                    guard let self = self, let awaiter = self.statusAwaiter else { return }
                    self.statusAwaiter = nil
                    self.fallbackReadWorkItem?.cancel()
                    awaiter(.failure(AirBeamMiniV2ConfiguratorError.statusTimeout))
                }
            }
        }
    }

    /// Called by the reconnection path before re-attempting Status subscription.
    /// CoreBluetooth invalidates per-peripheral subscriptions across disconnect; we
    /// also need a fresh Status read because the device's state may have changed
    /// (e.g., HasSavedSession after a power cycle that interrupted a Running session).
    func prepareForReconnect() {
        runOnQueueSync {
            self.fallbackReadWorkItem?.cancel()
            self.fallbackReadWorkItem = nil
            self.statusAwaiter = nil
            self.lastStatus = nil
            self.syncDrainResetWorkItem?.cancel()
            self.syncDrainResetWorkItem = nil
            self.isActiveSyncDrainingStorage = false
            self.dispatcher.resetSessionStartGuard()
            for token in self.subscriptionTokens {
                _ = self.btCommunicator.unsubscribeCharacteristicObserver(token: token)
            }
            self.subscriptionTokens.removeAll()
            self.responseSubscribed = false
            self.measurementSubscribed = false
        }
    }

    func teardown() {
        runOnQueueSync {
            self.fallbackReadWorkItem?.cancel()
            self.fallbackReadWorkItem = nil
            self.statusAwaiter = nil
            self.syncDrainResetWorkItem?.cancel()
            self.syncDrainResetWorkItem = nil
            self.isActiveSyncDrainingStorage = false
            self._syncChunkInterceptor = nil
            self.dispatcher.cancelAll(AirBeamMiniV2ConfiguratorError.notImplemented)
            self.invalidateSetTimeTimerLocked()
            for token in self.subscriptionTokens {
                _ = self.btCommunicator.unsubscribeCharacteristicObserver(token: token)
            }
            self.subscriptionTokens.removeAll()
            self.responseSubscribed = false
            self.measurementSubscribed = false
            self.mobileSessionActive = false
        }
    }

    private func ensureSubscriptions() {
        // Status (only Phase 1 awaiter cares; subscribe once)
        if subscriptionTokens.isEmpty {
            subscribe(uuid: V2BinaryProtocol.CharacteristicUUIDs.status) { [weak self] result in
                self?.handleStatusNotification(result)
            }
            subscribe(uuid: V2BinaryProtocol.CharacteristicUUIDs.sync) { [weak self] result in
                self?.handleSyncNotification(result)
            }
        }
        if !responseSubscribed {
            subscribe(uuid: V2BinaryProtocol.CharacteristicUUIDs.response) { [weak self] result in
                self?.handleResponseNotification(result)
            }
            responseSubscribed = true
        }
        if !measurementSubscribed {
            subscribe(uuid: V2BinaryProtocol.CharacteristicUUIDs.measurement) { [weak self] result in
                self?.handleMeasurementNotification(result)
            }
            measurementSubscribed = true
        }
    }

    private func subscribe(uuid: CBUUID, notify: @escaping (Result<Data?, Error>) -> Void) {
        do {
            let token = try btCommunicator.subscribeToCharacteristic(
                for: device,
                characteristic: CharacteristicUUID(value: uuid.uuidString),
                notify: notify
            )
            subscriptionTokens.append(token)
        } catch {
            Log.error("V2 subscribe to \(uuid) failed: \(error)")
        }
    }

    private func scheduleStatusFallbackRead() {
        queue.async { [weak self] in
            guard let self = self, self.lastStatus == nil else { return }
            let work = DispatchWorkItem { [weak self] in
                guard let self = self, self.lastStatus == nil else { return }
                Log.info("V2 status fallback read after no notification within \(V2BinaryProtocol.statusFallbackReadDelaySeconds)s")
                do {
                    try self.btPeripheral.readValue(
                        for: self.device,
                        serviceID: V2BinaryProtocol.ServiceUUID.v2.uuidString,
                        characteristicID: V2BinaryProtocol.CharacteristicUUIDs.status.uuidString
                    )
                } catch {
                    Log.error("V2 status fallback read failed: \(error)")
                }
            }
            self.fallbackReadWorkItem = work
            self.queue.asyncAfter(deadline: .now() + V2BinaryProtocol.statusFallbackReadDelaySeconds, execute: work)
        }
    }

    private func handleStatusNotification(_ result: Result<Data?, Error>) {
        queue.async { [weak self] in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                guard let data = data else {
                    Log.error("V2 status notification missing data")
                    return
                }
                switch V2BinaryProtocol.decodeStatus(data) {
                case .success(let status):
                    Log.info("V2 status decoded: \(status)")
                    // ReadyToSync (0x03) only arrives during a manual sync —
                    // it carries the file_size for the progress UI. Don't
                    // overwrite `lastStatus` (which callers query for ETA on
                    // the start-path dialog from the prior HasSavedSession).
                    if case .readyToSync(let fileSize) = status {
                        self.activeManualSync?.handleReadyToSync(fileSize: fileSize)
                        return
                    }
                    self.lastStatus = status
                    self.fallbackReadWorkItem?.cancel()
                    let awaiter = self.statusAwaiter
                    self.statusAwaiter = nil
                    awaiter?(.success(status))
                case .failure(let error):
                    Log.error("V2 status decode failed: \(error) raw=\(data as NSData)")
                    let awaiter = self.statusAwaiter
                    self.statusAwaiter = nil
                    awaiter?(.failure(AirBeamMiniV2ConfiguratorError.statusDecodeFailed))
                }
            case .failure(let error):
                Log.error("V2 status notification error: \(error)")
                let awaiter = self.statusAwaiter
                self.statusAwaiter = nil
                awaiter?(.failure(error))
            }
        }
    }

    private func handleResponseNotification(_ result: Result<Data?, Error>) {
        switch result {
        case .success(let data):
            guard let data = data else { return }
            // While a manual sync is in flight, the orchestrator owns Ready /
            // Nack: Ready (0x22) settles the sync (success), Nack (0x06/0x04)
            // fails it. Ack is forwarded both ways so any concurrent setup
            // command still resolves (but in practice nothing else runs).
            let manual = queue.sync { self.activeManualSync }
            if let manual = manual,
               let frame = V2BinaryProtocol.decodeResponse(data) {
                switch frame {
                case .ready:
                    Log.info("V2 manual sync: Ready terminal")
                    manual.handleReady()
                    return
                case .nack(let err, let raw):
                    Log.error("V2 manual sync: Nack(0x\(String(raw, radix: 16))) \(err)")
                    manual.handleNack(err, raw: raw)
                    return
                case .ack:
                    Log.info("V2 manual sync: Ack")
                    // Fall through to dispatcher so other awaiters (if any)
                    // resolve too. In practice the manual flow has no
                    // outstanding ackHandler — but keeping the dispatcher
                    // call is harmless.
                    break
                default:
                    break
                }
            }
            dispatcher.handleNotification(data)
        case .failure(let error):
            Log.error("V2 response notification error: \(error)")
        }
    }

    private func handleMeasurementNotification(_ result: Result<Data?, Error>) {
        guard mobileSessionActive,
              case .success(let optional) = result,
              let data = optional,
              let live = V2MeasurementParser.parseLive(data),
              let uuid = configuredSessionUUID else { return }
        // Drop measurements that arrive before the recording controller has created the
        // Core Data session row — saving a stream against a nonexistent session fails.
        guard let active = activeSessionProvider.activeSession,
              active.session.uuid == uuid else { return }

        let streams = V2StreamFactory.makeStreams(pm1: Double(live.pm1),
                                                  pm25: Double(live.pm25))
        let locationless = active.session.locationless
        measurementsSaver.saveV2LiveMeasurement(streams.pm1,
                                                sessionUUID: uuid,
                                                time: live.timestamp,
                                                locationless: locationless)
        measurementsSaver.saveV2LiveMeasurement(streams.pm25,
                                                sessionUUID: uuid,
                                                time: live.timestamp,
                                                locationless: locationless)
        NotificationCenter.default.post(
            name: .v2MeasurementSaved,
            object: nil,
            userInfo: [AirCastingNotificationKeys.V2MeasurementSaved.sessionUUID: uuid]
        )
    }

    // MARK: - Sync chunk handling (Phase 3)

    private func handleSyncNotification(_ result: Result<Data?, Error>) {
        guard case .success(let optional) = result, let data = optional else {
            if case .failure(let error) = result {
                Log.error("V2 sync notification error: \(error)")
            }
            return
        }
        queue.async { [weak self] in
            guard let self = self else { return }
            self.bumpActiveSyncDrainingLocked()
            if let manual = self.activeManualSync {
                manual.handleSyncChunk(data)
                return
            }
            if let intercept = self._syncChunkInterceptor {
                intercept(data)
                return
            }
            self.persistSyncChunkLocked(data)
        }
    }

    // MARK: - Manual BLE sync (Phase 6 — StartBleSync 0x16)

    /// Called by `V2BleSyncOrchestrator.start(...)` to register itself as the
    /// active sync orchestrator and kick off the `StartBleSync (0x16)` write.
    /// Status `ReadyToSync (0x03)` and sync-characteristic chunks are routed
    /// to the orchestrator until `endManualSync` is called.
    func beginManualSync(orchestrator: V2BleSyncOrchestrator) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.activeManualSync = orchestrator
            // Drop any stale pending handlers without invoking their failure
            // completions — a stale `discardSession` completion from a
            // previously stopped session would call `btManager.disconnect`
            // mid-0x16 write and drop the BLE link before sync starts
            // (symptom: device LED flips blue → green, sync hangs).
            self.dispatcher.clearAllSilently()
            self.dispatcher.resetSessionStartGuard()
            self.writeCommand(V2BinaryProtocol.buildStartBleSync()) { [weak self] result in
                if case .failure(let error) = result {
                    Log.error("V2 manual sync: write 0x16 failed: \(error)")
                    self?.queue.async {
                        guard let self = self, self.activeManualSync === orchestrator else { return }
                        orchestrator.handleAbort(V2BleSyncOrchestrator.SyncError.writeFailed(error))
                    }
                }
            }
        }
    }

    /// Sends `DiscardSession (0x11)` mid-stream — firmware honors it even
    /// while `StartBleSync` is in flight, wiping on-device storage. The
    /// orchestrator's completion will resolve with `.cancelled` once Ready
    /// arrives (or it can ignore subsequent traffic if disconnected).
    func cancelManualSync(orchestrator: V2BleSyncOrchestrator) {
        queue.async { [weak self] in
            guard let self = self, self.activeManualSync === orchestrator else { return }
            self.writeCommand(V2BinaryProtocol.buildDiscardSession()) { result in
                if case .failure(let error) = result {
                    Log.error("V2 manual sync cancel: write 0x11 failed: \(error)")
                }
            }
        }
    }

    /// Called by the orchestrator on terminal Ready / Nack / abort to clear
    /// the active reference. Idempotent.
    func endManualSync(orchestrator: V2BleSyncOrchestrator) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if self.activeManualSync === orchestrator {
                self.activeManualSync = nil
            }
        }
    }

    /// Persist a batch of records collected by the manual-sync orchestrator
    /// for the currently active mobile session. Mirrors `persistSyncChunkLocked`
    /// but takes already-parsed records (the orchestrator parses incrementally
    /// for progress accounting).
    func persistManualSyncRecords(_ records: [V2SyncRecord]) {
        guard !records.isEmpty else { return }
        // Open the save batch on the caller thread so a concurrent
        // `stopSampling` (the finish-dialog calls us then immediately
        // requests stop) defers its buffer wipe until our save loop
        // ends. The lookup + record save loop itself runs on
        // `queue.async` so an 8000-record sync replay doesn't freeze
        // the SwiftUI dialog button handler that triggered it.
        guard let preResolvedUUID = self.configuredSessionUUID else {
            Log.info("V2 manual sync persist: no configured session UUID (\(records.count) records).")
            return
        }
        v2LocationBackfillCoordinator.beginSaveBatch(sessionUUID: preResolvedUUID)

        queue.async { [weak self] in
            guard let self = self else { return }
            defer { self.v2LocationBackfillCoordinator.endSaveBatch(sessionUUID: preResolvedUUID) }
            guard let sessionUUID = self.configuredSessionUUID else {
                Log.info("V2 manual sync persist: no configured session UUID (\(records.count) records).")
                return
            }
            if let statusUUID = self.lastStatus?.sessionUUID,
               let configuredParsed = UUID(uuidString: sessionUUID.rawValue),
               statusUUID != configuredParsed {
                Log.warning("V2 manual sync persist dropped: device session \(statusUUID) != active \(configuredParsed)")
                return
            }
            guard let active = self.activeSessionProvider.activeSession,
                  active.session.uuid == sessionUUID else {
                Log.info("V2 manual sync persist: active session missing or uuid mismatch.")
                return
            }
            let locationless = active.session.locationless
            let overrides: [CLLocationCoordinate2D?]
            if locationless {
                overrides = Array(repeating: nil, count: records.count)
            } else {
                overrides = self.v2LocationBackfillCoordinator.locations(
                    for: sessionUUID,
                    at: records.map { $0.timestamp }
                )
            }
            for (index, record) in records.enumerated() {
                let streams = V2StreamFactory.makeStreams(pm1: Double(record.pm1),
                                                          pm25: Double(record.pm25))
                let backfill = overrides[index]
                self.measurementsSaver.saveV2SyncMeasurement(streams.pm1,
                                                             sessionUUID: sessionUUID,
                                                             time: record.timestamp,
                                                             locationless: locationless,
                                                             locationOverride: backfill)
                self.measurementsSaver.saveV2SyncMeasurement(streams.pm25,
                                                             sessionUUID: sessionUUID,
                                                             time: record.timestamp,
                                                             locationless: locationless,
                                                             locationOverride: backfill)
            }
            NotificationCenter.default.post(
                name: .v2MeasurementSaved,
                object: nil,
                userInfo: [AirCastingNotificationKeys.V2MeasurementSaved.sessionUUID: sessionUUID]
            )
        }
    }

    /// Convenience: build + return the orchestrator. The caller owns its
    /// lifetime; while the orchestrator is `start`ed, it's referenced from
    /// `activeManualSync` on this configurator.
    func makeManualSyncOrchestrator() -> V2BleSyncOrchestrator {
        V2BleSyncOrchestrator(configurator: self)
    }

    private func persistSyncChunkLocked(_ data: Data) {
        guard let records = V2MeasurementParser.parseSyncChunk(data), !records.isEmpty else {
            Log.warning("V2 sync chunk parse failed or empty: \(data as NSData)")
            return
        }
        guard let sessionUUID = configuredSessionUUID else {
            Log.info("V2 sync chunk dropped: no configured session UUID yet (\(records.count) records).")
            return
        }
        // Compare device's reported session UUID (from last Status) to the active app
        // session UUID — drop chunks belonging to an older session still on device storage.
        if let statusUUID = lastStatus?.sessionUUID,
           let configuredParsed = UUID(uuidString: sessionUUID.rawValue),
           statusUUID != configuredParsed {
            Log.warning("V2 sync chunk dropped: device session \(statusUUID) != active \(configuredParsed)")
            return
        }
        guard let active = activeSessionProvider.activeSession,
              active.session.uuid == sessionUUID else {
            Log.info("V2 sync chunk dropped: active session missing or uuid mismatch.")
            return
        }

        let locationless = active.session.locationless
        // Bracket the chunk processing as a save batch so a racing
        // `stopSampling` defers its buffer wipe until we finish.
        v2LocationBackfillCoordinator.beginSaveBatch(sessionUUID: sessionUUID)
        defer { v2LocationBackfillCoordinator.endSaveBatch(sessionUUID: sessionUUID) }
        let overrides: [CLLocationCoordinate2D?]
        if locationless {
            overrides = Array(repeating: nil, count: records.count)
        } else {
            overrides = v2LocationBackfillCoordinator.locations(
                for: sessionUUID,
                at: records.map { $0.timestamp }
            )
        }
        for (index, record) in records.enumerated() {
            let streams = V2StreamFactory.makeStreams(pm1: Double(record.pm1),
                                                      pm25: Double(record.pm25))
            let backfill = overrides[index]
            measurementsSaver.saveV2SyncMeasurement(streams.pm1,
                                                    sessionUUID: sessionUUID,
                                                    time: record.timestamp,
                                                    locationless: locationless,
                                                    locationOverride: backfill)
            measurementsSaver.saveV2SyncMeasurement(streams.pm25,
                                                    sessionUUID: sessionUUID,
                                                    time: record.timestamp,
                                                    locationless: locationless,
                                                    locationOverride: backfill)
        }
        NotificationCenter.default.post(
            name: .v2MeasurementSaved,
            object: nil,
            userInfo: [AirCastingNotificationKeys.V2MeasurementSaved.sessionUUID: sessionUUID]
        )
    }

    private func bumpActiveSyncDrainingLocked() {
        let wasDraining = isActiveSyncDrainingStorage
        isActiveSyncDrainingStorage = true
        syncDrainResetWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.queue.async {
                guard let self = self, self.isActiveSyncDrainingStorage else { return }
                self.isActiveSyncDrainingStorage = false
                self.postSyncDrainNotificationLocked(false)
            }
        }
        syncDrainResetWorkItem = work
        queue.asyncAfter(deadline: .now() + Self.syncDrainIdleTimeoutSeconds, execute: work)
        if !wasDraining {
            postSyncDrainNotificationLocked(true)
        }
    }

    private func postSyncDrainNotificationLocked(_ draining: Bool) {
        let deviceUUID = device.uuid
        NotificationCenter.default.post(
            name: .v2SyncDrainChanged,
            object: nil,
            userInfo: [
                AirCastingNotificationKeys.V2SyncDrainChanged.deviceUUID: deviceUUID,
                AirCastingNotificationKeys.V2SyncDrainChanged.isDraining: draining
            ]
        )
    }

    // MARK: - Reconnection (Phase 3)

    /// Called by the recording controller after BLE reconnect once Status notification
    /// has been received. Handles Scenario A (Running) and Scenario B (HasSavedSession).
    func resumeSessionAfterReconnect(uuid: SessionUUID,
                                     completion: @escaping (Result<Void, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.configuredSessionUUID = uuid
            // Open the live-measurement gate immediately. The Core Data session row
            // already exists (we're resuming, not creating), and ContinueSession's
            // Ready can lag the device's first live indication by several seconds
            // (12 s observed on real firmware) — gating measurements on the Ready
            // callback drops them silently in that window.
            self.mobileSessionActive = true
            guard let parsedExpected = UUID(uuidString: uuid.rawValue) else {
                completion(.failure(AirBeamMiniV2ConfiguratorError.missingSessionUUID))
                return
            }
            self.subscribeAndAwaitStatus { [weak self] statusResult in
                guard let self = self else { return }
                switch statusResult {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let status):
                    // Firmware loses wall-clock across power-cycle reboots — live
                    // Measurement indications stream with timestamps in the boot-counter
                    // range (epoch ≈ device uptime), which fall outside the session's
                    // 2026 chart window. Push SetTime before any session-state command
                    // so subsequent live indications carry the correct wall-clock.
                    self.writeCommand(V2BinaryProtocol.buildSetTime()) { writeResult in
                        if case .failure(let error) = writeResult {
                            Log.error("V2 reconnect SetTime write failed: \(error)")
                        }
                    }
                    switch status {
                    case .running(_, let deviceUUID):
                        guard deviceUUID == parsedExpected else {
                            Log.error("V2 reconnect Running with mismatched uuid device=\(deviceUUID) app=\(parsedExpected)")
                            completion(.failure(AirBeamMiniV2ConfiguratorError.sessionUUIDMismatch))
                            return
                        }
                        // Scenario A: no command needed; firmware streams sync + live automatically.
                        self.queue.async { self.mobileSessionActive = true }
                        self.scheduleHourlySetTime()
                        completion(.success(()))
                    case .hasSavedSession(_, let deviceUUID, _, _):
                        guard deviceUUID == parsedExpected else {
                            Log.error("V2 reconnect HasSavedSession with mismatched uuid device=\(deviceUUID) app=\(parsedExpected)")
                            completion(.failure(AirBeamMiniV2ConfiguratorError.sessionUUIDMismatch))
                            return
                        }
                        self.sendContinueSession { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .success:
                                self.queue.async { self.mobileSessionActive = true }
                                self.scheduleHourlySetTime()
                                completion(.success(()))
                            case .failure(let error):
                                Log.error("V2 ContinueSession failed: \(error)")
                                completion(.failure(error))
                            }
                        }
                    case .idle, .readyToSync:
                        completion(.failure(AirBeamMiniV2ConfiguratorError.unexpectedStatusForResume))
                    }
                }
            }
        }
    }

    private func sendContinueSession(completion: @escaping (Result<Void, Error>) -> Void) {
        // Firmware transitions to Running on Ack alone; subsequent Ready arrives as a
        // heartbeat. Resolve on Ack so we don't block resume on the periodic Ready.
        dispatcher.resetSessionStartGuard()
        dispatcher.awaitAckThenReady { result in
            // Ack-then-Ready handler resolves on Ready; ContinueSession's Ack is
            // sufficient — but the dispatcher only exposes ackThenReady. Reuse it:
            // if Ready never arrives (heartbeat-only), the caller already started
            // sync handling regardless, so failure here is informational only.
            completion(result)
        }
        writeCommand(V2BinaryProtocol.buildContinueSession()) { [weak self] result in
            if case .failure(let error) = result {
                self?.dispatcher.cancelAll(error)
            }
        }
    }

    // MARK: - Command writes

    private func writeCommand(_ payload: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try btPeripheral.sendMessage(
                data: payload,
                to: device,
                serviceID: V2BinaryProtocol.ServiceUUID.v2.uuidString,
                characteristicID: V2BinaryProtocol.CharacteristicUUIDs.command.uuidString,
                completion: { result in
                    if case .failure(let error) = result {
                        Log.error("V2 command write failed: \(error)")
                    }
                    completion(result)
                }
            )
        } catch {
            Log.error("V2 command write threw: \(error)")
            completion(.failure(error))
        }
    }

    // MARK: - AirBeamConfigurator

    /// V2 has no auth handshake. configureSession is called from ConnectingABViewModel
    /// after the BLE connect lands. Here we make sure subscriptions are up, await Status,
    /// then send GetSensors + the initial SetTime so the device is ready for a NewSessionConfig.
    func configureSession(uuid: SessionUUID, completion: @escaping (Result<Void, Error>) -> Void) {
        configuredSessionUUID = uuid
        subscribeAndAwaitStatus { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.requestSensorInfo { sensorResult in
                    switch sensorResult {
                    case .success(let info):
                        self.queue.async { self.sensorInfo = info }
                        self.sendSetTime()
                        completion(.success(()))
                    case .failure(let error):
                        Log.error("V2 GetSensors failed: \(error)")
                        // Sensor metadata is hardcoded as a fallback — proceed.
                        self.sendSetTime()
                        completion(.success(()))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func configureMobileSession(location: CLLocationCoordinate2D, intervalSeconds: Int?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uuid = configuredSessionUUID else {
            completion(.failure(AirBeamMiniV2ConfiguratorError.missingSessionUUID))
            return
        }
        let proceedNewSession: () -> Void = { [weak self] in
            self?.sendNewSessionConfigMobile(uuid: uuid, intervalSeconds: intervalSeconds) { result in
                switch result {
                case .success:
                    self?.queue.async { self?.mobileSessionActive = true }
                    self?.scheduleHourlySetTime()
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        if case .hasSavedSession = lastStatus {
            sendDiscardSession { result in
                switch result {
                case .success: proceedNewSession()
                case .failure(let error): completion(.failure(error))
                }
            }
        } else {
            proceedNewSession()
        }
    }

    func configureFixedCellularSession(uuid: SessionUUID,
                                       location: CLLocationCoordinate2D,
                                       date: Date,
                                       completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AirBeamMiniV2ConfiguratorError.notImplemented))
    }

    /// V1 protocol entry point — not used for V2 fixed sessions.
    /// The V2 path goes through `configureV2FixedSession(...)` from
    /// `AirBeamFixedWifiSessionCreator` after `POST /api/v3/fixed_sessions`
    /// returns the session_token + sensor indices.
    func configureFixedWifiSession(uuid: SessionUUID,
                                   location: CLLocationCoordinate2D,
                                   date: Date,
                                   wifiSSID: String,
                                   wifiPassword: String,
                                   completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AirBeamMiniV2ConfiguratorError.notImplemented))
    }

    /// V2 fixed session — sends `NewSessionConfig (0x13)` with mode=fixed, the
    /// session_token from the backend's `/api/v3/fixed_sessions` response, and
    /// the user's WiFi credentials. Waits for Ack→Ready before completing.
    /// Caller is responsible for disconnecting BLE on success.
    func configureV2FixedSession(uuid: SessionUUID,
                                 sessionTokenHex: String,
                                 pm1Index: UInt8,
                                 pm25Index: UInt8,
                                 wifiSSID: String,
                                 wifiPassword: String,
                                 completion: @escaping (Result<Void, Error>) -> Void) {
        configuredSessionUUID = uuid
        guard let parsedUUID = UUID(uuidString: uuid.rawValue) else {
            completion(.failure(AirBeamMiniV2ConfiguratorError.missingSessionUUID))
            return
        }
        guard let payload = V2BinaryProtocol.buildNewSessionConfigFixed(
            uuid: parsedUUID,
            pm1Index: pm1Index,
            pm25Index: pm25Index,
            sessionTokenHex: sessionTokenHex,
            wifiSSID: wifiSSID,
            wifiPassword: wifiPassword
        ) else {
            completion(.failure(AirBeamMiniV2ConfiguratorError.statusDecodeFailed))
            return
        }
        let preview = payload.prefix(38).map { String(format: "%02x", $0) }.joined()
        Log.info("V2 NewSessionConfig fixed payload (\(payload.count)B) header[0..38]=\(preview) ssid.len=\(wifiSSID.utf8.count) pwd.len=\(wifiPassword.utf8.count)")
        let proceed: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.dispatcher.resetSessionStartGuard()
            self.dispatcher.awaitAckThenReady(completion: completion)
            // Override the fake-UTC SetTime sent in `configureSession` with real UTC
            // before NewSessionConfig: BE applies `to_local_as_utc(epoch, session.time_zone)`
            // when ingesting the device's V2 fixed measurement uploads, so a fake-UTC
            // device clock would double-shift wall-clock numerals forward by the
            // phone-TZ offset and put the dashboard card / graph hours ahead of the
            // phone time. Mobile sessions keep the fake-UTC default since they save
            // device timestamps directly to Core Data without a BE round-trip.
            self.writeCommand(V2BinaryProtocol.buildSetTime(date: Date())) { writeResult in
                if case .failure(let error) = writeResult {
                    Log.error("V2 fixed SetTime (real UTC) write failed: \(error)")
                }
            }
            self.writeCommand(payload) { [weak self] result in
                if case .failure(let error) = result {
                    self?.dispatcher.cancelAll(error)
                }
            }
        }
        if case .hasSavedSession = lastStatus {
            sendDiscardSession { result in
                switch result {
                case .success: proceed()
                case .failure(let error): completion(.failure(error))
                }
            }
        } else {
            proceed()
        }
    }

    func configureSDSync(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AirBeamMiniV2ConfiguratorError.notImplemented))
    }

    func clearSDCard(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.failure(AirBeamMiniV2ConfiguratorError.notImplemented))
    }

    /// Stop a running V2 session: write 0x11, wait for Ready before resolving.
    /// Caller (recording controller) must wait for the completion before disconnecting.
    func discardSession(completion: @escaping (Result<Void, Error>) -> Void) {
        queue.async { [weak self] in
            self?.mobileSessionActive = false
            self?.invalidateSetTimeTimerLocked()
        }
        sendDiscardSession(completion: completion)
    }

    // MARK: - Command flows

    private func requestSensorInfo(completion: @escaping (Result<String, Error>) -> Void) {
        dispatcher.awaitSensorInfo(completion: completion)
        writeCommand(V2BinaryProtocol.buildGetSensors()) { [weak self] result in
            if case .failure(let error) = result {
                // Dispatcher's stored sensorInfo handler IS `completion`; cancelAll fires it once.
                self?.dispatcher.cancelAll(error)
            }
        }
    }

    private func sendSetTime() {
        writeCommand(V2BinaryProtocol.buildSetTime()) { result in
            if case .failure(let error) = result {
                Log.error("V2 SetTime write failed: \(error)")
            }
        }
    }

    private func sendDiscardSession(completion: @escaping (Result<Void, Error>) -> Void) {
        dispatcher.resetSessionStartGuard()
        dispatcher.awaitAckThenReady(completion: completion)
        writeCommand(V2BinaryProtocol.buildDiscardSession()) { [weak self] result in
            if case .failure(let error) = result {
                self?.dispatcher.cancelAll(error)
            }
        }
    }

    private func sendNewSessionConfigMobile(uuid: SessionUUID,
                                            intervalSeconds: Int?,
                                            completion: @escaping (Result<Void, Error>) -> Void) {
        guard let parsedUUID = UUID(uuidString: uuid.rawValue) else {
            completion(.failure(AirBeamMiniV2ConfiguratorError.missingSessionUUID))
            return
        }
        // Clamp into the wire-format u16 range; anything below 1 falls back to the
        // V2 mobile default (1s). Values above UInt16.max are pinned — firmware
        // wouldn't accept a wider field anyway.
        let interval: UInt16
        if let raw = intervalSeconds, raw >= 1 {
            interval = UInt16(min(raw, Int(UInt16.max)))
        } else {
            interval = V2BinaryProtocol.mobileIntervalSeconds
        }
        dispatcher.resetSessionStartGuard()
        dispatcher.awaitAckThenReady(completion: completion)
        writeCommand(V2BinaryProtocol.buildNewSessionConfigMobile(uuid: parsedUUID, interval: interval)) { [weak self] result in
            if case .failure(let error) = result {
                self?.dispatcher.cancelAll(error)
            }
        }
    }

    // MARK: - Hourly SetTime timer (mobile only)

    private func scheduleHourlySetTime() {
        DispatchQueue.main.async { [weak self] in
            self?.runOnQueueSync {
                guard let self = self else { return }
                self.invalidateSetTimeTimerLocked()
                let timer = Timer(timeInterval: 3600, repeats: true) { [weak self] _ in
                    self?.queue.async {
                        guard let self = self, self.mobileSessionActive else { return }
                        self.sendSetTime()
                    }
                }
                self.setTimeTimer = timer
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }

    private func invalidateSetTimeTimerLocked() {
        setTimeTimer?.invalidate()
        setTimeTimer = nil
    }
}
