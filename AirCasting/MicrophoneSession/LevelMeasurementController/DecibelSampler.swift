// Created by Lunar on 15/05/2022.
//

import Foundation

final class DecibelSampler: LevelSampler {
    enum DecibelSamplerError: Error {
        case couldntGetMicrophoneLevel
    }
    
    private let microphone: Microphone
    
    init(microphone: Microphone) {
        self.microphone = microphone
    }
    
    func sample(completion: (Result<Double, LevelSamplerError>) -> Void) {
        guard microphone.state != .interrupted else {
            completion(.failure(LevelSamplerError.disconnected))
            return
        }
        do {
            if microphone.state == .notRecording { try microphone.startRecording() }
            guard let db = microphone.getCurrentDecibelLevel() else {
                throw DecibelSamplerError.couldntGetMicrophoneLevel
            }
            completion(.success(db))
        } catch {
            completion(.failure(LevelSamplerError.readError(error)))
        }
    }
    
    deinit {
        do {
            try microphone.stopRecording()
        } catch {
            Log.error("Couldn't stop recording: \(error)")
        }
    }
}
