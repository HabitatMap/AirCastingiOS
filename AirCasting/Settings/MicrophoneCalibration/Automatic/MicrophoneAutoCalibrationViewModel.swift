// Created by Lunar on 16/08/2022.
//

import Resolver
import Foundation

class MicrophoneAutoCalibrationViewModel: ObservableObject {
    enum CurrentState: Equatable {
        case idle
        case calibrating
        case done
    }
    @Published var state: CurrentState = .idle
    @Published var alert: AlertInfo?
    
    @Injected private var calibrator: MicrophoneCalibration
    @Injected private var permissions: MicrophonePermissions
    @Injected private var store: MicrophoneCalibrationValueWritable
    
    func calibrateTapped() {
        Log.info("Mic calibration started")
        guard permissions.permissionGranted else {
            Log.info("Mic permissions not set, asking.")
            permissions.requestRecordPermission { result in
                guard result else { return }
                self.calibrateTapped()
            }
            return
        }
        guard calibrator.isAvailable else {
            Log.info("Microphone is busy, calibration aborted")
            alert = InAppAlerts.microphoneUnavailableForCalibration()
            return
        }
        performCalibration()
    }
    
    private func performCalibration() {
        state = .calibrating
        calibrator.startCalibration { [weak self] result in
            do {
                let newZero = try result.get().lowestPower
                Log.info("Mic calibration ended with new low power: \(newZero)")
                self?.store.zeroLevelAdjustment = newZero + MicrophoneCalibrationConstants.automaticCalibrationPadding
                self?.state = .done
                Log.info("Mic calibration store adjusted.")
            } catch {
                Log.info("Mic calibration failed with error: \(error.localizedDescription)")
                self?.alert = InAppAlerts.microphoneCalibrationError(error: error)
                self?.state = .idle
            }
        }
    }
}
