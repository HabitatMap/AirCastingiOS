// Created by Lunar on 15/05/2022.
//

import Foundation

enum MicrophoneState {
    case recording, interrupted, notRecording
}

protocol Microphone {
    var state: MicrophoneState { get }
    func getCurrentDecibelLevel() -> Double?
    func startRecording() throws
    func stopRecording() throws
}

protocol MicrophonePermissions {
    var permissionGranted: Bool { get }
    func requestRecordPermission(_ response: @escaping (Bool) -> Void)
}
