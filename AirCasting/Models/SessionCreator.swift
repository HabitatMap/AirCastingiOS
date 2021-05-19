// Created by Lunar on 11/05/2021.
//

import Foundation

#if DEBUG
/// Only to be used for swiftui previews
final class PreviewSessionCreator: SessionCreator {
    func createSession(_ sessionContext: CreateSessionContext, completion: @escaping (Result<Void, Error>) -> Void) {}
}
#endif

protocol SessionCreator {
    func createSession(_ sessionContext: CreateSessionContext, completion: @escaping (Result<Void, Error>) -> Void)
}

final class MicrophoneSessionCreator: SessionCreator {
    enum MicrophoneSessionCreatorError: Swift.Error {
        case invalidCreateSessionContext(CreateSessionContext)
    }
    let microphoneManager: MicrophoneManager

    init(microphoneManager: MicrophoneManager) {
        self.microphoneManager = microphoneManager
    }

    func createSession(_ sessionContext: CreateSessionContext, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionType = sessionContext.sessionType,
              let sessionUUID = sessionContext.sessionUUID,
              let startingLocation = sessionContext.startingLocation else {
            assertionFailure("invalidCreateSessionContext \(sessionContext)")
            completion(.failure(MicrophoneSessionCreatorError.invalidCreateSessionContext(sessionContext)))
            return
        }

        let session = Session(uuid: sessionUUID,
                              type: sessionType,
                              name: sessionContext.sessionName,
                              deviceType: sessionContext.deviceType,
                              location: startingLocation,
                              startTime: Date())

        do {
            try microphoneManager.startRecording(session: session)
            completion(.success(()))
        } catch {
            assertionFailure("Can't start recording microphone session: \(error)")
            completion(.failure(error))
        }
    }
}
