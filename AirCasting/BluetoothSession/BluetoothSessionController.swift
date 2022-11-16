// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver
import CoreLocation

protocol BluetoothSessionController {
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
    func resumeRecording(device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void)
    func stopRecordingSession(with uuid: SessionUUID)
}

class MobileAirBeamSessionRecordingController: BluetoothSessionController {
    @Injected var mobilePeripheralSessionManager: MobilePeripheralSessionManager
    @Injected var measurementsRecorder: MeasurementsRecordingServices
    @Injected var locationTracker: LocationTracker
    
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        Resolver.resolve(AirBeamConfigurator.self, args: device)
            .configureMobileSession(location: session.location ?? CLLocationCoordinate2D(latitude: 200, longitude: 200)) { result in
                switch result {
                case .success():
                    Log.info("## Successfully configured AB")
                    self.mobilePeripheralSessionManager.startRecording(session: session, device: device)
                    self.measurementsRecorder.record(with: device) { [weak self] stream in
                        self?.mobilePeripheralSessionManager.handlePeripheralMeasurement(AirBeamMeasurement(device: device, measurementStream: stream))
                    }
                    completion(.success(()))
                case .failure(let error):
                    Log.error("## Failed to configure AB: \(error)")
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
}
