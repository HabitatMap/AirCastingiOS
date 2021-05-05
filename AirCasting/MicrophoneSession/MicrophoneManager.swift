//
//  Created by Lunar on 11/03/2021.
//

import Foundation
import AVFoundation
import CoreAudio
import CoreData

class MicrophoneManager: ObservableObject {
    static private let recordSettings: [String: Any] = [
        AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
    ]
    
    var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    private var session: Session?
    var measurementStream: MeasurementStream?
    
    lazy var notificationCenter = NotificationCenter.default
    
    //This variable is used to block recording more than one microphone session at a time
    private(set) var isRecording = false
    
    private var recorder: AVAudioRecorder!
    private(set) lazy var audioSession = AVAudioSession.sharedInstance()
    //remove or use instead of the requestPermissionGranted function
    var recordPermission: AVAudioSession.RecordPermission { audioSession.recordPermission }
    private var levelTimer = Timer()
    
    private var locationProvider = LocationProvider()
    
    func startRecording(session: Session) throws {
        if isRecording { return }
        
        if audioSession.recordPermission != .granted {
            throw MicrophoneSessionError.permissionNotGranted
        }
        
        addInterruptionsObserver()
        
        self.session = session
        createDBStream(for: session)
        saveInitialMicThreshold()
        locationProvider.requestLocation()
        
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        
        try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
        try audioSession.setActive(true)
        try recorder = AVAudioRecorder(url:url, settings: MicrophoneManager.recordSettings)
        
        
        recorder.isMeteringEnabled = true
        recorder.record()
        isRecording = true
        
        getMeasurement()
        levelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(getMeasurement), userInfo: nil, repeats: true)
        
    }
    
    func stopRecording() throws {
        levelTimer.invalidate()
        removeInterruptionsObserver()
        isRecording = false
        recorder.stop()
        recorder = nil
        guard let session = session else {
            throw MicrophoneSessionError.sessionNotSet
        }
        session.status = .FINISHED
        try context.save()
    }
    
    func recordPermissionGranted() -> Bool {
        return audioSession.recordPermission == .granted
    }
    
    func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        audioSession.requestRecordPermission(response)
    }
}

private extension MicrophoneManager {
    @objc func getMeasurement() {
        if !recorder.isRecording {
            recorder.record()
        }
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)
        try! createMeasurement(value: level)
    }
    
    @objc func handleInterruption(notification: Notification) {
        let typeValue = notification.userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
        let type = AVAudioSession.InterruptionType(rawValue: typeValue)!
        
        switch type {
        case .ended:
            levelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(getMeasurement), userInfo: nil, repeats: true)
        case .began:
            fallthrough
        @unknown default:
            levelTimer.invalidate()
            session!.status = .DISCONNETCED
        }
    }
    
    func createMeasurement(value: Float) throws {
        let startingLocation = obtainCurrentLocation()
        
        let measurement = Measurement(context: self.context)
        
        measurement.latitude = startingLocation.latitude
        measurement.longitude = startingLocation.longitude
        measurement.value = Double(value)
        measurement.time = Date()
        
        session!.endTime = measurement.time
        session!.status = .RECORDING
        
        measurementStream!.addToMeasurements(measurement)
        
        try context.save()
    }
    
    func createDBStream(for session: Session) {
        let stream = MeasurementStream(context: self.context)
        stream.sensorName = "Phone Microphone-dB"
        stream.sensorPackageName = "Builtin"
        stream.measurementType = "Sound Level"
        stream.measurementShortType = "db"
        stream.unitName = "decibels"
        stream.unitSymbol = "dB"
        stream.thresholdVeryLow = 20
        stream.thresholdLow = 60
        stream.thresholdMedium = 70
        stream.thresholdHigh = 80
        stream.thresholdVeryHigh = 100
        stream.gotDeleted = false
        
        measurementStream = stream
        
        session.addToMeasurementStreams(measurementStream!)
    }
    
    func saveInitialMicThreshold() {
        let existing: SensorThreshold? = try? context.existingObject(sensorName: "db")
        if existing == nil {
            let thresholds: SensorThreshold = try! context.createObject(sensorName: "db")
            #warning("TODO: change thresholds values from dbFS to db")
            thresholds.thresholdVeryLow = -100
            thresholds.thresholdLow = -40
            thresholds.thresholdMedium = -30
            thresholds.thresholdHigh = -20
            thresholds.thresholdVeryHigh = 10
        }
    }
    
    func obtainCurrentLocation() -> CLLocationCoordinate2D {
        locationProvider.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 200.0, longitude: 200.0)
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
        case sessionNotSet
        case permissionNotGranted
    }
}
