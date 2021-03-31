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
    
    private var recorder: AVAudioRecorder!
    private var levelTimer = Timer()
    
    private let LEVEL_THRESHOLD: Float = -10.0
    
    func startRecording() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSessionRecordPermission.granted:
            print("Permission granted")
            record()
        case AVAudioSessionRecordPermission.denied:
            //TODO: Direct user to settings
            print("Pemission denied")
        case AVAudioSessionRecordPermission.undetermined:
            print("Request permission here")
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                if (granted) {
                    print("Permission granted")
                    self.record()
                  }
                  else {
                    //TODO: Direct user to settings
                    print("Pemission denied")
                  }
            })
        @unknown default:
            //TODO: throw exception
            print("Unknown permission")
        }
    }
    
    func record() {
        
        
        let url = NSURL.fileURL(withPath: "dev/null")
        
        let recordSettings: [String: Any] = [
            AVFormatIDKey:              kAudioFormatAppleIMA4,
            AVSampleRateKey:            44100.0,
            AVNumberOfChannelsKey:      2,
            AVEncoderBitRateKey:        12800,
            AVLinearPCMBitDepthKey:     16,
            AVEncoderAudioQualityKey:   AVAudioQuality.max.rawValue
        ]
        
//        let audioSession = AVAudioSession.sharedInstance()
        do {
//            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
//            try audioSession.setActive(true)
            try recorder = AVAudioRecorder(url:url, settings: recordSettings)
            
        } catch {
            return
        }
        
        recorder.prepareToRecord()
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
