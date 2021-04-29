//
//  Created by Lunar on 11/03/2021.
//

import Foundation
import AVFoundation
import CoreAudio
import CoreLocation

final class MicrophoneManager: ObservableObject {
    static private let recordSettings: [String: Any] = [
        AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
    ]

    private let measurementStreamStorage: MeasurementStreamStorage
    private let notificationCenter: NotificationCenter
    private var measurementStreamLocalID: MeasurementStreamLocalID?

    //This variable is used to block recording more than one microphone session at a time
    private(set) var isRecording = false
    private var recorder: AVAudioRecorder!
    private lazy var audioSession = AVAudioSession.sharedInstance()
    private var levelTimer: Timer?
    private(set) var session: Session?
    private lazy var locationProvider = LocationProvider()

    init(measurementStreamStorage: MeasurementStreamStorage, notificationCenter: NotificationCenter = .default) {
        self.measurementStreamStorage = measurementStreamStorage
        self.notificationCenter = notificationCenter
    }

    func startRecording(session: Session) throws {
        if isRecording {
            return
        }
        
        if audioSession.recordPermission != .granted {
            throw MicrophoneSessionError.permissionNotGranted
        }
        self.session = session
        addInterruptionsObserver()

        try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
        try audioSession.setActive(true)
        try recorder = AVAudioRecorder.init(url: URL(fileURLWithPath: "/dev/null", isDirectory: true), settings: MicrophoneManager.recordSettings)
        recorder.isMeteringEnabled = true
        measurementStreamLocalID = try createMeasurementStream(for: session)
        locationProvider.requestLocation()
        isRecording = true
        recorder.record()
        try sampleMeasurement()
        levelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
    }
    
    func stopRecording() throws {
        levelTimer?.invalidate()
        removeInterruptionsObserver()
        isRecording = false
        recorder.stop()
        recorder = nil
        try! measurementStreamStorage.updateSessionStatus(.FINISHED, for: session!.uuid)
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
}

private extension MicrophoneManager {
    func sampleMeasurement() throws {
        recorder.updateMeters()
        let value = Double(recorder.averagePower(forChannel: 0))
        try measurementStreamStorage.addMeasurementValue(value, at: obtainCurrentLocation(), toStreamWithID: measurementStreamLocalID!)
    }

    @objc func timerTick() {
        try! sampleMeasurement()
    }
    
    @objc func handleInterruption(notification: Notification) {
        let typeValue = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
        let type = AVAudioSession.InterruptionType(rawValue: typeValue)!
        
        switch type {
        case .ended:
            if !recorder.isRecording {
                recorder.record()
            }
            levelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
        case .began:
            fallthrough
        @unknown default:
            levelTimer?.invalidate()
            try! measurementStreamStorage.updateSessionStatus(.DISCONNETCED, for: session!.uuid)
        }
    }
    

    func createMeasurementStream(for session: Session) throws -> MeasurementStreamLocalID {
        let stream = MeasurementStream(id: nil,
                                       sensorName: "Phone Microphone-dB",
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
        return try measurementStreamStorage.createSessionAndMeasurementStream(session, stream)
    }
    
    func obtainCurrentLocation() -> CLLocationCoordinate2D? {
        locationProvider.currentLocation?.coordinate
    }
    
    func addInterruptionsObserver() {
        notificationCenter.addObserver(self,
                                       selector: #selector(handleInterruption),
                                       name: AVAudioSession.interruptionNotification,
                                       object: audioSession)
    }
    
    func removeInterruptionsObserver() {
        notificationCenter.removeObserver(self, name: AVAudioSession.interruptionNotification, object: audioSession)
    }
    
    enum MicrophoneSessionError: Error {
        case permissionNotGranted
    }
}

