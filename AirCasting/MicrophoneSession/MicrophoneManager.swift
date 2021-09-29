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
        
        createMeasurementStream(for: session) { result in
            switch result {
            case .success(let id):
                self.measurementStreamLocalID = id
            case .failure(let error):
                Log.info("\(error)")
            }
        }
        locationProvider.requestLocation()
        isRecording = true
        recorder.record()
        sampleMeasurement()
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
        measurementStreamStorage.accessStorage { storage in
            do {
                try! storage.updateSessionStatus(.DISCONNECTED, for: self.session!.uuid)
            }
        }
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
    func sampleMeasurement() {
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let decibels = Double(power + 90.0)
        let location = obtainCurrentLocation()
        
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.addMeasurementValue(decibels, at: location, toStreamWithID: self.measurementStreamLocalID!)
            } catch {
                Log.info("\(error)")
            }
        }
    }

    @objc func timerTick() {
        sampleMeasurement()
    }

    func createMeasurementStream(for session: Session, completion: @escaping(Result<MeasurementStreamLocalID, Error>) -> Void) {
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
                let id = try storage.createSessionAndMeasurementStream(session, stream)
                completion(.success(id))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func obtainCurrentLocation() -> CLLocationCoordinate2D? {
        locationProvider.currentLocation?.coordinate
    }
    
    enum MicrophoneSessionError: Error {
        case permissionNotGranted
    }
}

