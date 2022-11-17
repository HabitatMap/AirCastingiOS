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
    @Injected var mobilePeripheralSessionManager: MobilePeripheralSessionManager
    @Injected var measurementsSaver: MeasurementsSavingService
    @Injected var measurementsRecorder: MeasurementsRecordingServices
    @Injected var activeSessionProvider: ActiveMobileSessionProvidingService
    @Injected var locationTracker: LocationTracker
    
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        Resolver.resolve(AirBeamConfigurator.self, args: device)
            .configureMobileSession(location: session.location ?? CLLocationCoordinate2D(latitude: 200, longitude: 200)) { [self] result in
                switch result {
                case .success():
                    Log.info("Successfully configured AB")
                    measurementsSaver.createSession(session: session, device: device) { [self] result in
                        switch result {
                        case .success():
                            Log.info("Successfully created session \(session.uuid) in the database")
                            if !session.locationless {
                                self.locationTracker.start()
                            }
                            activeSessionProvider.setActiveSession(session: session, device: device)
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
        mobilePeripheralSessionManager.finishSession(with: uuid)
        measurementsRecorder.stopRecording()
    }
    
    private func recordMeasurements(for activeSession: MobileSession) {
        measurementsRecorder.record(with:activeSession.device) { [weak self] stream in
            self?.measurementsSaver.handlePeripheralMeasurement(stream, sessionUUID: activeSession.session.uuid, locationless: activeSession.session.locationless)
        }
    }
}
