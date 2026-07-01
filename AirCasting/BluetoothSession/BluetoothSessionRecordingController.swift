// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver
import CoreLocation

protocol BluetoothSessionRecordingController {
    func startRecording(session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
    func resumeRecording(device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
    func stopRecordingSession(with uuid: SessionUUID, databaseChange: (MobileSessionFinishingStorage) -> Void)
}

enum SessionRecordingControllerError: Error {
    case sessionAlreadyInProgress
    case noSessionToResume
}

class MobileAirBeamSessionRecordingController: BluetoothSessionRecordingController {
    @Injected private var measurementsSaver: MeasurementsSavingService
    @Injected private var storage: MobileSessionFinishingStorage
    @Injected private var measurementsRecorder: MeasurementsRecordingServices
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var locationTracker: LocationTracker
    @Injected private var btManager: BluetoothConnectionHandler
    @Injected private var v2LocationBackfillCoordinator: V2LocationBackfillCoordinator
    private var isRecording = false

    func startRecording(session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        // Step 1: Configure AB
        // Gate on `activeSession` (the cross-component source-of-truth for
        // an in-flight recording) rather than the local `isRecording` flag.
        // `isRecording` is only flipped false inside `stopRecordingSession`'s
        // BLE teardown path; SDCardMobileSessionFinisher writes status=FINISHED
        // + clears `activeSession` without going through stopRecordingSession,
        // leaving `isRecording` stuck true. The next new-session attempt then
        // hits this guard and surfaces "SessionRecordingController error 0"
        // even though there's no live session.
        guard activeSessionProvider.activeSession == nil else {
            completion(.failure(SessionRecordingControllerError.sessionAlreadyInProgress))
            Log.error("Tried to record a session when there was another session being recorded")
            return
        }
        // Make sure the local flag reflects reality before we proceed —
        // `recordMeasurements` will set it back to true.
        isRecording = false
        // Step 1: Configure AB for mobile session
        let intervalSeconds = session.measurementInterval.flatMap { Int($0) }
        Resolver.resolve(AirBeamConfigurator.self, args: device)
            .configureMobileSession(location: session.location ?? CLLocationCoordinate2D(latitude: 200, longitude: 200),
                                    intervalSeconds: intervalSeconds) { [self] result in
                switch result {
                case .success():
                    Log.info("Successfully configured AB")
                    // Step 2: Create session
                    measurementsSaver.createSession(session: session, device: device) { [weak self] result in
                        guard let self else { return }
                        switch result {
                        case .success():
                            Log.info("Successfully created session \(session.uuid) in the database")
                            // Step 3: Start tracking location
                            if !session.locationless {
                                self.locationTracker.start()
                            }
                            // V2: arm the disconnect-window location backfill so that any
                            // measurements synced after a BLE outage can be matched to phone
                            // GPS fixes captured while the device was offline.
                            if device.firmwareVersion == .v2 && !session.locationless {
                                let interval = TimeInterval(session.measurementInterval.flatMap(Int.init) ?? 1)
                                self.v2LocationBackfillCoordinator.startSampling(
                                    sessionUUID: session.uuid,
                                    intervalSeconds: interval
                                )
                            }
                            // Step 4: Set active session in active session provider
                            self.activeSessionProvider.setActiveSession(session: session, device: device)
                            // Step 5: Start recording measurements
                            self.recordMeasurements(for: self.activeSessionProvider.activeSession!)
                            completion(.success(()))
                        case .failure(let error):
                            Log.error("Failed to create session: \(error)")
                            completion(.failure(error))
                        }
                    }
                case .failure(let error):
                    Log.error("Failed to configure AB: \(error)")
                    completion(.failure(error))
                }
            }
    }

    func resumeRecording(device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        // V2: firmware auto-resumes streaming on reconnect. Status determines which
        // scenario applies:
        //   - Running: nothing to send; sync chunks + live indications flow on their own.
        //   - HasSavedSession: send ContinueSession (0x10) to transition the device to Running.
        if device.firmwareVersion == .v2 {
            if let activeSession = self.activeSessionProvider.activeSession {
                self.resumeV2Session(device: device, activeSession: activeSession, completion: completion)
                return
            }
            // No in-memory active session. The provider is in-memory only and is emptied
            // on app kill, so a cold relaunch mid-session lands here. Rebuild the active
            // session from the on-disk DISCONNECTED row this device owns and bind it,
            // instead of silently reporting success (which left configuredSessionUUID
            // unbound, so the entire offline backfill was dropped on reconnect). If there
            // is genuinely nothing to resume, fail loudly — never resolve silently.
            storage.accessStorage { [weak self] hidden in
                guard let self = self else { return }
                let restored: Session?
                do {
                    restored = try hidden.disconnectedMobileSession(forPeripheralUUID: device.uuid)
                } catch {
                    Log.error("V2 resumeRecording: failed to look up DISCONNECTED session for \(device.uuid): \(error)")
                    restored = nil
                }
                DispatchQueue.main.async {
                    guard let restored = restored else {
                        Log.error("V2 resumeRecording: no active session in memory and no DISCONNECTED session on disk for \(device.uuid) — cannot resume.")
                        completion(.failure(SessionRecordingControllerError.noSessionToResume))
                        return
                    }
                    Log.info("V2 resumeRecording: restored active session \(restored.uuid) from disk for reconnecting device \(device.uuid)")
                    self.activeSessionProvider.setActiveSession(session: restored, device: device)
                    guard let activeSession = self.activeSessionProvider.activeSession else {
                        completion(.failure(SessionRecordingControllerError.noSessionToResume))
                        return
                    }
                    self.resumeV2Session(device: device, activeSession: activeSession, completion: completion)
                }
            }
            return
        }

        Resolver.resolve(AirBeamConfigurator.self, args: device)
            .configureMobileSession(location: locationTracker.location.value?.coordinate ?? .undefined,
                                    intervalSeconds: nil) { [weak self] result in
                switch result {
                case .success():
                    defer { completion(.success(())) }
                    guard let self else { return }
                    guard !self.isRecording else {
                        // We want to make sure we are not recording more than one session at once
                        // and resumeRecording can be called during automatic reconnect as well
                        return
                    }

                    guard let activeSession = self.activeSessionProvider.activeSession else { return }

                    if !activeSession.session.locationless {
                        self.locationTracker.start()
                    }
                    self.recordMeasurements(for: activeSession)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    private func resumeV2Session(device: any BluetoothDevice,
                                 activeSession: MobileSession,
                                 completion: @escaping (Result<Void, Error>) -> Void) {
        let configurator = Resolver.resolve(AirBeamMiniV2Configurator.self, args: device)
        configurator.resumeSessionAfterReconnect(uuid: activeSession.session.uuid) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                if !activeSession.session.locationless {
                    self.locationTracker.start()
                }
                // V2: re-arm the backfill sampler. Idempotent — if the app wasn't
                // killed, the existing sampler stays; on cold-relaunch this is the
                // path that restarts location capture for the previously DISCONNECTED
                // session.
                if !activeSession.session.locationless {
                    let interval = TimeInterval(activeSession.session.measurementInterval.flatMap(Int.init) ?? 1)
                    self.v2LocationBackfillCoordinator.startSampling(
                        sessionUUID: activeSession.session.uuid,
                        intervalSeconds: interval
                    )
                }
                self.isRecording = true
                completion(.success(()))
            case .failure(let error):
                Log.error("V2 resume after reconnect failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    func stopRecordingSession(with uuid: SessionUUID, databaseChange: (MobileSessionFinishingStorage) -> Void) {
        // Database change is performed for both active and disconnected sessions
        databaseChange(storage)

        // V2: tear down backfill sampler + purge persisted samples. Must run
        // for every finish path — including "Finish & don't sync" on a
        // DISCONNECTED card where `activeSession` is nil (e.g. after a
        // cold-launch where `bootstrap()` restarted the sampler but the
        // active-session provider never rebound). Idempotent + safe for
        // unknown UUIDs, so unconditional invocation is fine for V1 and
        // for the active branch below alike.
        v2LocationBackfillCoordinator.stopSampling(sessionUUID: uuid)

        // The code below the guard is performed only for active sessions
        guard let activeSession = activeSessionProvider.activeSession, activeSession.session.uuid == uuid else { return }

        let device = activeSession.device
        let locationless = activeSession.session.locationless

        // Tear down reconnection-relevant state synchronously, BEFORE any async wait
        // (V2 DiscardSession Ready) and before triggering BLE disconnect. Otherwise a
        // disconnect — whether driven by our cancelPeripheralConnection or by the user
        // power-cycling the device mid-stop — fires didDisconnectPeripheral while
        // activeSession is still set, the reconnection controller sees
        // shouldReconnect == true, and the app silently reconnects (and stays
        // connected, hiding the device from the next scan list).
        activeSessionProvider.clearActiveSession()
        isRecording = false
        if !locationless {
            locationTracker.stop()
        }

        let proceedToDisconnect: () -> Void = { [weak self] in
            guard let self = self else { return }
            // Diagnostic: with all backfill drained, log the session's measurement
            // coverage so a data gap can be classified from the finish log
            // (null-location rows = export-excluded/recoverable vs a true row gap
            // = never captured). See MeasurementsSavingService.logMeasurementCoverage.
            self.measurementsSaver.logMeasurementCoverage(for: uuid)
            try? self.btManager.disconnect(from: device)
            if device.firmwareVersion == .v1 {
                self.measurementsRecorder.stopRecording()
            } else {
                Resolver.resolve(V2ConfiguratorRegistry.self).release(deviceUUID: device.uuid)
            }
        }

        switch device.firmwareVersion {
        case .v1:
            proceedToDisconnect()
        case .v2:
            let configurator = Resolver.resolve(AirBeamMiniV2Configurator.self, args: device)
            // Wait for any in-flight active-sync drain before sending 0x11 —
            // otherwise firmware wipes on-device storage mid-stream and we
            // permanently lose records that hadn't been replayed yet.
            configurator.awaitSyncDrain { drainResult in
                if case .failure(let error) = drainResult {
                    Log.error("[V2SYNC] stop: sync drain wait timed out (\(error)) for \(uuid). Proceeding with DiscardSession; un-replayed records still on the device will be WIPED and lost.")
                } else {
                    Log.info("[V2SYNC] stop: sync drained cleanly before DiscardSession for \(uuid).")
                }
                configurator.discardSession { result in
                    if case .failure(let error) = result {
                        Log.error("[V2SYNC] DiscardSession on stop failed: \(error). Disconnecting anyway.")
                    }
                    proceedToDisconnect()
                }
            }
        }
    }

    private func recordMeasurements(for activeSession: MobileSession) {
        isRecording = true
        measurementsSaver.changeStatusToRecording(for: activeSession.session.uuid)
        // V2 owns its own DB writes (parses binary measurement indications inside the
        // configurator and calls saveV2LiveMeasurement directly). Skip the V1 semicolon
        // string parser path entirely.
        guard activeSession.device.firmwareVersion == .v1 else { return }
        measurementsRecorder.record(with: activeSession.device) { [weak self] stream in
            self?.measurementsSaver.handlePeripheralMeasurement(stream, sessionUUID: activeSession.session.uuid, locationless: activeSession.session.locationless)
        }
    }
}
