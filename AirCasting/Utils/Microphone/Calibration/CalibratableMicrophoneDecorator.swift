// Created by Lunar on 16/08/2022.
//

import Foundation
import Resolver

class CalibratableMicrophoneDecorator: Microphone {
    let microphone: Microphone
    let constAdjustment = 10.0
    @Injected private var calibrationValueProvider: MicrophoneCalibraionValueProvider
    
    var state: MicrophoneState { microphone.state }
    
    init(microphone: Microphone) {
        self.microphone = microphone
        Log.info("Initial zero dB level: \(calibrationValueProvider.zeroLevelAdjustment)")
    }
    
    func getCurrentDecibelLevel() -> Double? {
        microphone.getCurrentDecibelLevel().map { $0 - calibrationValueProvider.zeroLevelAdjustment + constAdjustment }
    }
    
    func startRecording() throws { try microphone.startRecording() }
    func stopRecording() throws { try microphone.stopRecording() }
}
