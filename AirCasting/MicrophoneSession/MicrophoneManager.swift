//
//  Created by Lunar on 11/03/2021.
//

import Foundation
import AVFoundation
import CoreAudio
import CoreLocation

final class MicrophoneManager: NSObject, ObservableObject {
    static private let recordSettings: [String: Any] = [
        AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
    ]

    private let measurementStreamStorage: MeasurementStreamStorage
    private var measurementStreamLocalID: MeasurementStreamLocalID?

    //This variable is used to block recording more than one microphone session at a time
    private(set) var isRecording = false
    private var recorder: AVAudioRecorder!
    private lazy var audioSession = AVAudioSession.sharedInstance()
    private var levelTimer: Timer?
    private(set) var session: Session?
    private lazy var locationProvider = LocationProvider()

    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
        super.init()
    }

    func startRecording(session: Session) throws {
        if isRecording {
            return
        }
        
        if audioSession.recordPermission != .granted {
            throw MicrophoneSessionError.permissionNotGranted
        }
        self.session = session

        try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
        try audioSession.setActive(true)
        try recorder = AVAudioRecorder(url: URL(fileURLWithPath: "/dev/null", isDirectory: true), settings: MicrophoneManager.recordSettings)
        recorder.isMeteringEnabled = true
        recorder.delegate = self
        measurementStreamLocalID = try createMeasurementStream(for: session)
        locationProvider.requestLocation()
        isRecording = true
        recorder.record()
        try sampleMeasurement()
        levelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
    }
    
    func stopRecording() throws {
        levelTimer?.invalidate()
        isRecording = false
        recorder.stop()
        recorder = nil
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

extension MicrophoneManager: AVAudioRecorderDelegate {
    func audioRecorderBeginInterruption(_ recorder: AVAudioRecorder) {
        Log.warning("audio recorder interruption began")
        levelTimer?.invalidate()
        try! measurementStreamStorage.updateSessionStatus(.DISCONNECTED, for: session!.uuid)
    }

    func audioRecorderEndInterruption(_ recorder: AVAudioRecorder, withOptions flags: Int) {
        Log.info("audio recorder end interruption")
        if !recorder.isRecording {
            recorder.record()
        }
        levelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        assertionFailure("audio recorder encode error did occur \(String(describing: error))")
    }
}

private extension MicrophoneManager {
    func sampleMeasurement() throws {
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let decibels = Double(power + 90.0)
        let location = obtainCurrentLocation()
        Log.debug("New mic measurement \(decibels) at \(String(describing: location))")
        try measurementStreamStorage.addMeasurementValue(decibels, at: location, toStreamWithID: measurementStreamLocalID!)
    }

    @objc func timerTick() {
        try! sampleMeasurement()
    }

    func createMeasurementStream(for session: Session) throws -> MeasurementStreamLocalID {
        let stream = MeasurementStream(id: nil,
                                       sensorName: Strings.SensorsData.microphone,
                                       sensorPackageName: "Builtin",
                                       measurementType: "Sound Level",
                                       measurementShortType: "db",
                                       unitName: "decibels",
                                       unitSymbol: "dB",
                                       thresholdVeryHigh: 100,
                                       thresholdHigh: 80,
                                       thresholdMedium: 70,
                                       thresholdLow: 60,
                                       thresholdVeryLow: -100)
        #warning("TODO: Change thresholdVeryLow to 20")
        return try measurementStreamStorage.createSessionAndMeasurementStream(session, stream)
    }
    
    func obtainCurrentLocation() -> CLLocationCoordinate2D? {
        locationProvider.currentLocation?.coordinate
    }
    
    enum MicrophoneSessionError: Error {
        case permissionNotGranted
    }
}

