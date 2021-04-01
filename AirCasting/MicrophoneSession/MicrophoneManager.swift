//
//  microphoneManager.swift
//  AirCasting
//
//  Created by Anna Olak on 11/03/2021.
//

import Foundation
import AVFoundation
import CoreAudio

class MicrophoneManager: ObservableObject {
    var measurements: [Float] = []
    //    var measurementStream: MeasurementStream
    
    private var recorder: AVAudioRecorder!
    private var levelTimer = Timer()
    
    private let LEVEL_THRESHOLD: Float = -10.0
    
    
    func startRecording() {
        
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
        
        levelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(levelTimerCallback), userInfo: nil, repeats: true)
        
        print("recording")
    }
    
    @objc func levelTimerCallback() {
            recorder.updateMeters()

            let level = recorder.averagePower(forChannel: 0)
            
            print(level)
        }
    
    func stopRecording() {
        levelTimer.invalidate()
    }
    
}
