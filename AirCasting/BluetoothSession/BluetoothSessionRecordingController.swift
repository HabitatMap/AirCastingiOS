// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver
import CoreLocation

protocol BluetoothSessionRecordingController {
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
    func resumeRecording(device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
    func stopRecordingSession(with uuid: SessionUUID)
}

class MobileAirBeamSessionRecordingController: BluetoothSessionRecordingController {
    @Injected private var measurementsSaver: MeasurementsSavingService
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    @Injected private var measurementsRecorder: MeasurementsRecordingServices
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected private var locationTracker: LocationTracker
    @Injected private var btManager: BluetoothConnectionHandler
    
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        // Step 1: Configure AB
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
        // Info: we're not changing the sessions `status` property here to `.RECORDING` because it is currently
        // being done by the MeasurementStreamStorage class automagically.
        // This is something we might want to change at some point.
    }
    
    func stopRecordingSession(with uuid: SessionUUID) {
        // Database change should be performed for active and disconnected sessions
        performDatabaseChange(for: uuid)
        
        guard let activeSession = activeSessionProvider.activeSession, activeSession.session.uuid == uuid else { return }
        btManager.disconnect(from: activeSession.device)
        if !activeSession.session.locationless {
            locationTracker.stop()
        }
        
        activeSessionProvider.clearActiveSession()
        measurementsRecorder.stopRecording()
    }
    
    private func recordMeasurements(for activeSession: MobileSession) {
        measurementsRecorder.record(with:activeSession.device) { [weak self] stream in
            self?.measurementsSaver.handlePeripheralMeasurement(stream, sessionUUID: activeSession.session.uuid, locationless: activeSession.session.locationless)
        }
    }
    
    private func performDatabaseChange(for uuid: SessionUUID) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.FINISHED, for: uuid)
                try storage.updateSessionEndtime(DateBuilder.getRawDate(), for: uuid)
            } catch {
                // TODO: Add completion here and show an alert ?
                Log.error("Unable to change session status to finished because of an error: \(error)")
            }
        }
    }
}
