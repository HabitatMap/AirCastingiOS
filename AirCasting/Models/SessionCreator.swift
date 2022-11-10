// Created by Lunar on 11/05/2021.
//

import Foundation
import CoreLocation
import Resolver

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
    @Injected private var microphoneManager: MicrophoneManager

    func createSession(_ sessionContext: CreateSessionContext, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionType = sessionContext.sessionType,
              let sessionUUID = sessionContext.sessionUUID,
              let contribute = sessionContext.contribute,
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
                              startTime: DateBuilder.getFakeUTCDate(),
                              contribute: contribute,
                              locationless: sessionContext.locationless,
                              status: .NEW)

        do {
            try microphoneManager.startRecording(session: session)
            completion(.success(()))
        } catch {
            assertionFailure("Can't start recording microphone session: \(error)")
            completion(.failure(error))
        }
    }
}

final class MobilePeripheralSessionCreator: SessionCreator {
    enum MobilePeripheralSessionCreatorError: Swift.Error {
        case invalidCreateSessionContext(CreateSessionContext)
    }
    @Injected private var recorder: BluetoothSessionController
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    @Injected private var measurementStreamStorage: MeasurementStreamStorage

    func createSession(_ sessionContext: CreateSessionContext, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionType = sessionContext.sessionType,
              let sessionUUID = sessionContext.sessionUUID,
              let startingLocation = sessionContext.startingLocation,
              let contribute = sessionContext.contribute
        else {
            assertionFailure("invalidCreateSessionContext \(sessionContext)")
            completion(.failure(MobilePeripheralSessionCreatorError.invalidCreateSessionContext(sessionContext)))
            return
        }
        do {
            guard let device = sessionContext.device else {
                assertionFailure("invalidCreateSessionContext \(sessionContext)")
                throw MobilePeripheralSessionCreatorError.invalidCreateSessionContext(sessionContext)
            }
            let session = Session(uuid: sessionUUID,
                                  type: sessionType,
                                  name: sessionContext.sessionName,
                                  deviceType: sessionContext.deviceType,
                                  location: startingLocation,
                                  startTime: DateBuilder.getFakeUTCDate(),
                                  contribute: contribute,
                                  locationless: sessionContext.locationless,
                                  tags: sessionContext.sessionTags,
                                  status: .NEW)
            Resolver.resolve(AirBeamConfigurator.self, args: device)
                .configureMobileSession(location: sessionContext.startingLocation ?? CLLocationCoordinate2D(latitude: 200, longitude: 200)) { result in
                    switch result {
                    case .success():
                        Log.info("## Successfully configured AB")
                        self.recorder.startRecording(session: session, device: device)
                        completion(.success(()))
                    case .failure(let error):
                        Log.error("## Failed to configure AB: \(error)")
                        completion(.failure(error))
                    }
                }
        } catch {
            assertionFailure("Can't start recording mobile bluetooth session: \(error)")
            completion(.failure(error))
        }
    }
}
