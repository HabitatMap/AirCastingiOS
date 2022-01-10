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
                              startTime: Date().currentUTCTimeZoneDate,
                              contribute: contribute)

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
    let mobilePeripheralSessionManager: MobilePeripheralSessionManager
    let userAuthenticationSession: UserAuthenticationSession
    @Injected private var measurementStreamStorage: MeasurementStreamStorage

    init(mobilePeripheralSessionManager: MobilePeripheralSessionManager, userAuthenticationSession: UserAuthenticationSession) {
        self.mobilePeripheralSessionManager = mobilePeripheralSessionManager
        self.userAuthenticationSession = userAuthenticationSession
    }

    func createSession(_ sessionContext: CreateSessionContext, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionType = sessionContext.sessionType,
              let sessionUUID = sessionContext.sessionUUID,
              let startingLocation = sessionContext.startingLocation,
              let contribute = sessionContext.contribute else {
            assertionFailure("invalidCreateSessionContext \(sessionContext)")
            completion(.failure(MobilePeripheralSessionCreatorError.invalidCreateSessionContext(sessionContext)))
            return
        }
        let session = Session(uuid: sessionUUID,
                              type: sessionType,
                              name: sessionContext.sessionName,
                              deviceType: sessionContext.deviceType,
                              location: startingLocation,
                              startTime: Date().currentUTCTimeZoneDate,
                              contribute: contribute,
                              tags: sessionContext.sessionTags,
                              status: .NEW)
        do {
            guard let peripheral = sessionContext.peripheral else {
                assertionFailure("invalidCreateSessionContext \(sessionContext)")
                throw MobilePeripheralSessionCreatorError.invalidCreateSessionContext(sessionContext)
            }
            AirBeam3Configurator(userAuthenticationSession: userAuthenticationSession,
                                 peripheral: peripheral).configureMobileSession(
                                    location: sessionContext.startingLocation ?? CLLocationCoordinate2D(latitude: 200, longitude: 200))
            mobilePeripheralSessionManager.startRecording(session: session, peripheral: peripheral)
            completion(.success(()))
        } catch {
            assertionFailure("Can't start recording mobile bluetooth session: \(error)")
            completion(.failure(error))
        }
    }
}
