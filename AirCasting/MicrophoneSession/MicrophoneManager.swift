//
//  Created by Lunar on 11/03/2021.
//

import Foundation
import Resolver
import AVFoundation
import CoreAudio
import CoreLocation
import UIKit

final class MicrophoneManager: NSObject, ObservableObject {
    static private let recordSettings: [String: Any] = [
        AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
    ]

    private let measurementStreamStorage: MeasurementStreamStorage
    private var measurementStreamLocalID: MeasurementStreamLocalID?

    // This variable is used to block recording more than one microphone session at a time
    private(set) var isRecording = false {
        didSet { isRecording ? interruptionHandler.resume() : interruptionHandler.pause() }
    }
    private var recorder: AVAudioRecorder?
    private lazy var audioSession = AVAudioSession.sharedInstance()
    private var levelTimer: Timer?
    private(set) var session: Session?
    @Injected private var locationTracker: LocationTracker
    private var interruptionHandler: AVSessionInterruptionHandler!

    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
        super.init()
        self.interruptionHandler = .init(observer: self, audioSession: audioSession)
        do {
            try recorder = AVAudioRecorder(url: URL(fileURLWithPath: "/dev/null", isDirectory: true), settings: MicrophoneManager.recordSettings)
        } catch {
            Log.error("Could not create AVAudioRecorder: \(error.localizedDescription)")
        }
    }

    func startRecording(session: Session) throws {
        guard !isRecording, let recorder = recorder else { return }
        
        if audioSession.recordPermission != .granted {
            throw MicrophoneSessionError.permissionNotGranted
        }
        self.session = session
        try setupAudioSession()
        try audioSession.setActive(true)
        recorder.isMeteringEnabled = true
        
        createMeasurementStream(for: session) { [weak self] result in
            switch result {
            case .success:
                if recorder.record() {
                    DispatchQueue.main.async {
                        self?.isRecording = true
                        if !session.locationless {
                            self?.locationTracker.start()
                        }
                        self?.levelTimer = self?.createTimer()
                    }
                }
            case .failure(let error):
                Log.error("Failed to create stream for microphone session: \(error)")
            }
        }
    }
    
    func stopRecording() {
        guard isRecording, let recorder = recorder else { return }
        levelTimer?.invalidate()
        if !(session?.locationless ?? false) {
            Log.info("## Stopping tracker")
            locationTracker.stop()
        }
        isRecording = false
        measurementStreamLocalID = nil
        recorder.pause()
    }

    deinit {
        levelTimer?.invalidate()
    }
    
    func recordPermissionGranted() -> Bool {
        audioSession.recordPermission == .granted
    }
    
    func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        audioSession.requestRecordPermission(response)
    }
    
    private func setupAudioSession() throws {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: [.duckOthers])
    }
    
    private func createTimer() -> Timer {
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
    }
}

extension MicrophoneManager: AVSessionInterruptionObserver {
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
        guard shouldResume == true, let recorder = recorder else { return }
        do {
            try resumeInterruptedRecording(audioRecorder: recorder)
        } catch {
            Log.error("Failed to resume audio session: \(error.localizedDescription)")
            // TODO: Decide on how to handle this situation
        }
    }
    
    private func pauseForRecordingInterruption() throws {
        levelTimer?.invalidate()
        recorder?.pause()
        try audioSession.setActive(false, options: [])
        disconnectCurrentSession()
    }
    
    private func resumeInterruptedRecording(audioRecorder: AVAudioRecorder) throws {
        try audioSession.setActive(true, options: [])
        guard audioRecorder.record() else { Log.warning("recording failed to resume!"); return }
        Log.info("recording resumed.")
        levelTimer = createTimer()
    }
    
    private func disconnectCurrentSession() {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.updateSessionStatus(.DISCONNECTED, for: self.session!.uuid)
            } catch {
                Log.error("Couldn't disconnect session! \(error.localizedDescription)")
            }
        }
    }
}

private extension MicrophoneManager {
    func sampleMeasurement(noLocation: Bool) {
        guard let recorder = recorder else { return }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        var decibels = Double(power + 90.0)
        (decibels < 0) ? decibels = 0 : nil
        // 117 lines ensure that we won't get something like -70 etc.
        let location = noLocation ? .undefined : obtainCurrentLocation()
        
        measurementStreamStorage.accessStorage { storage in
            do {
                if let streamID = self.measurementStreamLocalID {
                    try storage.addMeasurementValue(decibels, at: location, toStreamWithID: streamID)
                } else {
                    guard let streamID = try storage.existingMeasurementStream(self.session!.uuid, name: Constants.SensorName.microphone) else {
                        Log.error("Failed to find existing microphone stream")
                        return
                    }
                    self.measurementStreamLocalID = streamID
                    try storage.addMeasurementValue(decibels, at: location, toStreamWithID: streamID)
                }
            } catch {
                Log.error("Failed sampling measurement: \(error)")
            }
        }
    }

    @objc private func timerTick() {
        sampleMeasurement(noLocation: session?.locationless ?? false)
    }

    func createMeasurementStream(for session: Session, completion: @escaping(Result<Void, Error>) -> Void) {
        let stream = MeasurementStream(id: nil,
                                       sensorName: Constants.SensorName.microphone,
                                       sensorPackageName: "Builtin",
                                       measurementType: "Sound Level",
                                       measurementShortType: "db",
                                       unitName: "decibels",
                                       unitSymbol: "dB",
                                       thresholdVeryHigh: 100,
                                       thresholdHigh: 80,
                                       thresholdMedium: 70,
                                       thresholdLow: 60,
                                       thresholdVeryLow: 20)
        
        measurementStreamStorage.accessStorage { storage in
            do {
                _ = try storage.createSessionAndMeasurementStream(session, stream)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func obtainCurrentLocation() -> CLLocationCoordinate2D? {
        Log.info("Obtaining current location with: \(locationTracker.location.value)")
        return locationTracker.location.value?.coordinate
    }
    
    enum MicrophoneSessionError: Error {
        case permissionNotGranted
    }
}
