// Created by Lunar on 16/08/2022.
//

import Foundation
import Resolver

/// A `Microphone` decorator that adds the ability to adjust the output using the value from `MicrophoneCalibraionValueProvider`.
class CalibratableMicrophoneDecorator: Microphone {
    let microphone: Microphone
    @Injected private var calibrationValueProvider: MicrophoneCalibraionValueProvider
    
    var state: MicrophoneState { microphone.state }
    
    init(microphone: Microphone) {
        self.microphone = microphone
        Log.info("Initial zero dB level: \(self.calibrationValueProvider.zeroLevelAdjustment)")
    }
    
    func getCurrentDecibelLevel() -> Double? {
        microphone.getCurrentDecibelLevel().map { $0 + calibrationValueProvider.zeroLevelAdjustment }
    }
    
    func startRecording() throws { try microphone.startRecording() }
    func stopRecording() throws { try microphone.stopRecording() }
}
