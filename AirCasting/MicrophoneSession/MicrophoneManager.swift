//
//  microphoneManager.swift
//  AirCasting
//
//  Created by Anna Olak on 11/03/2021.
//

import Foundation
import AVFoundation
import CoreAudio
import CoreData

class MicrophoneManager: ObservableObject {
    var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    var measurements: [Float] = []
    var session: Session?
    var measurementStream: MeasurementStream?
    
    private var recorder: AVAudioRecorder!
    private var levelTimer = Timer()
    
    private let LEVEL_THRESHOLD: Float = -10.0
    
    func startRecording(session: Session) {
        self.session = session
        createDBStream()
        
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !isGranted {
                    // TODO: pop-up that informs user that we need access to mic with ability do go back to homescreen
                    fatalError("You must allow audio recording for this demo to work")
                }
            }
        }
        
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        
        let recordSettings: [String: Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
//        let audioSession = AVAudioSession.sharedInstance()
        do {
//            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
//            try audioSession.setActive(true)
            try recorder = AVAudioRecorder(url:url, settings: recordSettings)
            
        } catch {
            return
        }
        
        recorder.isMeteringEnabled = true
        recorder.record()
        
        levelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(getMeasurement), userInfo: nil, repeats: true)
        
        print("recording")
    }
    
    @objc func getMeasurement() {
        recorder.updateMeters()
        
        let level = recorder.averagePower(forChannel: 0)
        
        let measurement = Measurement(context: self.context)
        measurement.latitude = 200
        measurement.longitude = 200
        measurement.value = Double(level)
        measurement.time = Date()
        
        session?.endTime = measurement.time
        session?.status = 0
        
        measurementStream?.addToMeasurements(measurement)
        
        do {
            try context.save()
        } catch {
            print(error)
        }
    }
    
    func stopRecording() {
        levelTimer.invalidate()
    }
    
    private
    
    func createDBStream() {
        if let session = session {
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
    }
    
}
