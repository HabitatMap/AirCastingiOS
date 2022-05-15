// Created by Lunar on 15/05/2022.
//

import Foundation

class DecibelSampler: LevelSampler {
    private let microphone: Microphone
    
    init(microphone: Microphone) {
        self.microphone = microphone
    }
    
    func sample(completion: (Result<Double, Error>) -> Void) {
        do {
            guard microphone.state != .interrupted else { throw LevelSamplerDisconnectedError() }
            if microphone.state == .notRecording { try microphone.startRecording() }
            guard let db = microphone.getCurrentDecibelLevel() else {
                fatalError("MAJOR ERROR, SIR") //TODO: After testing put a throw in here
            }
            completion(.success(db))
        } catch {
            completion(.failure(error))
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
