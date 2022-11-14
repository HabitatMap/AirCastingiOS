// Created by Lunar on 04/11/2022.
//

import Foundation
import Resolver

protocol BluetoothSessionController {
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice)
    func stopRecordingSession(with uuid: SessionUUID)
}

class MobileAirBeamSessionRecordingController: BluetoothSessionController {
    @Injected var mobilePeripheralSessionManager: MobilePeripheralSessionManager
    @Injected var measurementsRecorder: MeasurementsRecordingServices
    
    func startRecording(session: Session, device: NewBluetoothManager.BluetoothDevice) {
        mobilePeripheralSessionManager.startRecording(session: session, device: device)
        measurementsRecorder.record(with: device) { [weak self] stream in
            self?.mobilePeripheralSessionManager.handlePeripheralMeasurement(AirBeamMeasurement(device: device, measurementStream: stream))
        }
    }
    
    func stopRecordingSession(with uuid: SessionUUID) {
        mobilePeripheralSessionManager.finishSession(with: uuid)
        measurementsRecorder.stopRecording()
    }
}
