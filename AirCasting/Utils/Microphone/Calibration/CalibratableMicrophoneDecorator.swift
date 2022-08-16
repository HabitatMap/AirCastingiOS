// Created by Lunar on 16/08/2022.
//

import Foundation
import Resolver

/// A `Microphone` decorator that adds the ability to adjust the output using the value from `MicrophoneCalibraionValueProvider`.
/// We assume that nobody will calibrate in a perfect 0dB room, so we're adding +20dB.
class CalibratableMicrophoneDecorator: Microphone {
    let microphone: Microphone
    @Injected private var calibrationValueProvider: MicrophoneCalibraionValueProvider
    
    var state: MicrophoneState { microphone.state }
    
    init(microphone: Microphone) {
        self.microphone = microphone
        Log.info("Initial zero dB level: \(calibrationValueProvider.zeroLevelAdjustment)")
    }
    
    func getCurrentDecibelLevel() -> Double? {
        microphone.getCurrentDecibelLevel().map { $0 - calibrationValueProvider.zeroLevelAdjustment + MicrophoneCalibrationConstants.automaticCalibrationPadding }
    }
    
    func startRecording() throws { try microphone.startRecording() }
    func stopRecording() throws { try microphone.stopRecording() }
}
