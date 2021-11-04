// Created by Lunar on 02/11/2021.
//

import AVKit

protocol AVSessionInterruptionObserver: AnyObject {
    func onAVSessionInteruptionStart()
    func onAVSessionInteruptionEnd(shouldResume: Bool)
}

final class AVSessionInterruptionHandler {
    private weak var observer: AVSessionInterruptionObserver?
    private let audioSession: AVAudioSession
    private var paused: Bool = false
    private let lock = NSLock()
    
    init(observer: AVSessionInterruptionObserver, audioSession: AVAudioSession = .sharedInstance()) {
        self.observer = observer
        self.audioSession = audioSession
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption(from:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: audioSession)
    }
    
    func pause() {
        lock.lock(); defer { lock.unlock() }
        paused = true
    }
    
    func resume() {
        lock.lock(); defer { lock.unlock() }
        paused = false
    }
    
    @objc
    private func handleInterruption(from notification: Notification) {
        lock.lock(); defer { lock.unlock() }
        guard !paused, let type = getInterruptionType(from: notification) else { return }
        switch type {
        case .began:
            Log.verbose("audio recorder interruption began")
            observer?.onAVSessionInteruptionStart()
        case .ended:
            Log.verbose("audio recorder interruption ended")
            let shouldResume = getResumeOptions(from: notification)?.contains(.shouldResume)
            observer?.onAVSessionInteruptionEnd(shouldResume: shouldResume ?? false)
        default: break
        }
    }
    
    private func getInterruptionType(from notification: Notification) -> AVAudioSession.InterruptionType? {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                  return nil
              }
        return type
    }
    
    private func getResumeOptions(from notification: Notification) -> AVAudioSession.InterruptionOptions? {
        guard let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt else { return nil }
        return AVAudioSession.InterruptionOptions(rawValue: optionsValue)
    }
}
