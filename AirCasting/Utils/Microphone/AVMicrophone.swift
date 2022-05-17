// Created by Lunar on 17/05/2022.
//

import Foundation
import AVFoundation
import UIKit

final class AVMicrophone: Microphone {
    enum AVMicrophoneError: Error {
        case permissionNotGranted, couldntStartRecorder
    }
    private(set) var state: MicrophoneState = .notRecording
    
    static private let recordSettings: [String: Any] = [
        AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
    ]
    private let recorder: AVAudioRecorder
    private let audioSession = AVAudioSession.sharedInstance()
    private var interruptionHandler: AVSessionInterruptionHandler!
    
    init() throws {
        self.recorder = try AVAudioRecorder(url: URL(fileURLWithPath: "/dev/null", isDirectory: true), settings: AVMicrophone.recordSettings)
        self.interruptionHandler = .init(observer: self, audioSession: audioSession)
    }
    
    func getCurrentDecibelLevel() -> Double? {
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        var decibels = Double(power + 90.0)
        (decibels < 0) ? decibels = 0 : nil
        return decibels
    }
    
    func startRecording() throws {
        guard state == .notRecording else { return }
        guard audioSession.recordPermission == .granted else { throw AVMicrophoneError.permissionNotGranted }
        UIApplication.shared.beginReceivingRemoteControlEvents()
        try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: [.duckOthers])
        try audioSession.setActive(true)
        recorder.isMeteringEnabled = true
        guard recorder.record() else { throw AVMicrophoneError.couldntStartRecorder }
        state = .recording
    }
    
    func stopRecording() throws {
        guard state != .notRecording else { return }
        recorder.pause()
        state = .notRecording
    }
}

extension AVMicrophone: AVSessionInterruptionObserver {
    func onAVSessionInteruptionStart() {
        Log.info("audio recorder interruption began")
        do {
            try pauseForRecordingInterruption()
        } catch {
            Log.error("Failed to pause audio session: \(error.localizedDescription)")
            // TODO: Decide on how to handle this situation
        }
    }
    
    func onAVSessionInteruptionEnd(shouldResume: Bool) {
        Log.info("audio recorder interruption ended (should resume? \(shouldResume ? "yes." : "no.")")
        guard shouldResume == true else { return }
        do {
            try resumeInterruptedRecording(audioRecorder: recorder)
        } catch {
            Log.error("Failed to resume audio session: \(error.localizedDescription)")
            // TODO: Decide on how to handle this situation
        }
    }
    
    private func pauseForRecordingInterruption() throws {
        recorder.pause()
        try audioSession.setActive(false, options: [])
        state = .interrupted
    }
    
    private func resumeInterruptedRecording(audioRecorder: AVAudioRecorder) throws {
        try audioSession.setActive(true, options: [])
        guard audioRecorder.record() else { Log.warning("recording failed to resume!"); return }
        state = .recording
        Log.info("recording resumed.")
    }
}

extension AVMicrophone: MicrophonePermissions {
    var permissionGranted: Bool { AVAudioSession.sharedInstance().recordPermission == .granted }
    func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission(response)
    }
}
