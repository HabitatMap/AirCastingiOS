// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver
import CoreLocation

protocol BluetoothSessionRecordingController {
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
    func resumeRecording(device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
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
    
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        // Step 1: Configure AB
        guard !isRecording else {
            // We want to make sure we are not recording more than one session at once
            completion(.failure(SessionRecordingControllerError.sessionAlreadyInProgress))
            assertionFailure("Tried to record a session when there was another session being recorded")
            return
        }
        Resolver.resolve(AirBeamConfigurator.self, args: device)
            .configureMobileSession(location: session.location ?? CLLocationCoordinate2D(latitude: 200, longitude: 200)) { [self] result in
                switch result {
                case .success():
                    Log.info("Successfully configured AB")
                    // Step 2: Create session
                    measurementsSaver.createSession(session: session, device: device) { [self] result in
                        switch result {
                        case .success():
                            Log.info("Successfully created session \(session.uuid) in the database")
                            // Step 3: Start tracking location
                            if !session.locationless {
                                self.locationTracker.start()
                            }
                            // Step 4: Set active session in active session provider
                            activeSessionProvider.setActiveSession(session: session, device: device)
                            // Step 5: Start recording measurements
                            recordMeasurements(for: activeSessionProvider.activeSession!)
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
    
    func resumeRecording(device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        Resolver.resolve(AirBeamConfigurator.self, args: device)
            .configureMobileSession(location: locationTracker.location.value?.coordinate ?? .undefined,
                                    completion: completion)
        
        guard !isRecording else {
            // We want to make sure we are not recording more than one session at once
            // and resumeRecording can be called during automatic reconnect as well
            return
        }
        
        if !(activeSessionProvider.activeSession?.session.locationless ?? true) {
            self.locationTracker.start()
        }
        recordMeasurements(for: activeSessionProvider.activeSession!)
    }
    
    func stopRecordingSession(with uuid: SessionUUID, databaseChange: (MobileSessionFinishingStorage) -> Void) {
        // Database change is performed for both active and disconnected sessions
        databaseChange(storage)
        
        // The code below the guard is performed only for active sessions
        guard let activeSession = activeSessionProvider.activeSession, activeSession.session.uuid == uuid else { return }
        
        btManager.disconnect(from: activeSession.device)
        if !activeSession.session.locationless {
            locationTracker.stop()
        }
        
        activeSessionProvider.clearActiveSession()
        measurementsRecorder.stopRecording()
        isRecording = false
    }
    
    private func recordMeasurements(for activeSession: MobileSession) {
        isRecording = true
        measurementsSaver.changeStatusToRecording(for: activeSession.session.uuid)
        measurementsRecorder.record(with: activeSession.device) { [weak self] stream in
            self?.measurementsSaver.handlePeripheralMeasurement(stream, sessionUUID: activeSession.session.uuid, locationless: activeSession.session.locationless)
        }
    }
}
