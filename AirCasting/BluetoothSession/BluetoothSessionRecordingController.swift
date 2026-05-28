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
}

class MobileAirBeamSessionRecordingController: BluetoothSessionRecordingController {
    @Injected private var measurementsSaver: MeasurementsSavingService
    @Injected private var storage: MobileSessionFinishingStorage
    @Injected private var measurementsRecorder: MeasurementsRecordingServices
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var locationTracker: LocationTracker
    @Injected private var btManager: BluetoothConnectionHandler
    private var isRecording = false

    func startRecording(session: Session, device: any BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        // Step 1: Configure AB
        guard !isRecording else {
            // We want to make sure we are not recording more than one session at once
            completion(.failure(SessionRecordingControllerError.sessionAlreadyInProgress))
            Log.error("Tried to record a session when there was another session being recorded")
            return
        }
        // Step 1: Configure AB for mobile session
        Resolver.resolve(AirBeamConfigurator.self, args: device)
            .configureMobileSession(location: session.location ?? CLLocationCoordinate2D(latitude: 200, longitude: 200)) { [self] result in
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
            guard let activeSession = self.activeSessionProvider.activeSession else {
                completion(.success(()))
                return
            }
            let configurator = Resolver.resolve(AirBeamMiniV2Configurator.self, args: device)
            configurator.resumeSessionAfterReconnect(uuid: activeSession.session.uuid) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    if !activeSession.session.locationless {
                        self.locationTracker.start()
                    }
                    self.isRecording = true
                    completion(.success(()))
                case .failure(let error):
                    Log.error("V2 resume after reconnect failed: \(error)")
                    completion(.failure(error))
                }
            }
            return
        }

        Resolver.resolve(AirBeamConfigurator.self, args: device)
            .configureMobileSession(location: locationTracker.location.value?.coordinate ?? .undefined) { [weak self] result in
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

    func stopRecordingSession(with uuid: SessionUUID, databaseChange: (MobileSessionFinishingStorage) -> Void) {
        // Database change is performed for both active and disconnected sessions
        databaseChange(storage)

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
            configurator.discardSession { result in
                if case .failure(let error) = result {
                    Log.error("V2 DiscardSession on stop failed: \(error). Disconnecting anyway.")
                }
                proceedToDisconnect()
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
