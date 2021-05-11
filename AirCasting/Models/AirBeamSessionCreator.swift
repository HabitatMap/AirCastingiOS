// Created by Lunar on 11/05/2021.
//

import Foundation
import CoreLocation

final class AirBeamSessionCreator: SessionCreator {
    enum AirBeamSessionCreatorError: Swift.Error {
        case invalidCreateSessionContext(CreateSessionContext)
    }
    let userAuthenticationSession: UserAuthenticationSession
    let measurementStreamStorage: MeasurementStreamStorage
    private let createSessionService: CreateSessionAPIService

    convenience init(measurementStreamStorage: MeasurementStreamStorage, userAuthenticationSession: UserAuthenticationSession) {
        self.init(measurementStreamStorage: measurementStreamStorage,
                  createSessionService: CreateSessionAPIService(authorisationService: userAuthenticationSession),
                  userAuthenticationSession: userAuthenticationSession)
    }

    init(measurementStreamStorage: MeasurementStreamStorage, createSessionService: CreateSessionAPIService, userAuthenticationSession: UserAuthenticationSession) {
        self.measurementStreamStorage = measurementStreamStorage
        self.createSessionService = createSessionService
        self.userAuthenticationSession = userAuthenticationSession
    }

    func createSession(_ sessionContext: CreateSessionContext, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionType = sessionContext.sessionType,
              let sessionUUID = sessionContext.sessionUUID else {
            assertionFailure("invalidCreateSessionContext \(sessionContext)")
            completion(.failure(AirBeamSessionCreatorError.invalidCreateSessionContext(sessionContext)))
            return
        }
        // Save data to app's database
        let session = Session(uuid: sessionUUID,
                              type: sessionType,
                              name: sessionContext.sessionName,
                              deviceType: sessionContext.deviceType,
                              location: sessionContext.startingLocation,
                              startTime: Date(),
                              tags: sessionContext.sessionTags)

        if session.type == SessionType.fixed {
            // if session is fixed: create an empty session on server,
            // then send AB auth data to connect to web session and data needed to start recording
            guard let name = session.name,
                  let startTime = session.startTime,
                  let peripheral = sessionContext.peripheral,
                  let wifiSSID = sessionContext.wifiSSID,
                  let wifiPassword = sessionContext.wifiPassword else {
                assertionFailure("invalidCreateSessionContext \(sessionContext)")
                completion(.failure(AirBeamSessionCreatorError.invalidCreateSessionContext(sessionContext)))
                return
            }

            #warning("TODO: change mocked data (contribute, is_indoor, notes, locaation, end_time)")
            let params = CreateSessionApi.SessionParams(uuid: sessionUUID,
                                                        type: .fixed,
                                                        title: name,
                                                        tag_list: session.tags ?? "",
                                                        start_time: startTime,
                                                        end_time: startTime,
                                                        contribute: false,
                                                        is_indoor: false,
                                                        notes: [],
                                                        version: 0,
                                                        streams: [:],
                                                        latitude: sessionContext.startingLocation?.latitude,
                                                        longitude: sessionContext.startingLocation?.longitude)
            createSessionService.createEmptyFixedWifiSession(input: .init(session: params,
                                                                          compression: true),
                                                             completion: { [measurementStreamStorage, userAuthenticationSession] result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let output):
                                    do {
                                        try measurementStreamStorage.createSession(session)
                                        try AirBeam3Configurator(userAuthenticationSession: userAuthenticationSession,
                                                                 peripheral: peripheral).configureFixedWifiSession(
                                            uuid: sessionUUID,
                                            location: sessionContext.startingLocation ?? CLLocationCoordinate2D(latitude: 200, longitude: 200),
                                            date: Date(),
                                            wifiSSID: wifiSSID,
                                            wifiPassword: wifiPassword)
                                        Log.warning("Created fixed Wifi session \(output)")
                                        completion(.success(()))
                                    } catch {
                                        completion(.failure(error))
                                    }
                                case .failure(let error):
                                    Log.warning("Failed to create fixed Wifi session \(error)")
                                    completion(.failure(error))
                                }
                            }
                         })
        } else {
            // if session is mobile: send AB data needed to start recording
            do {
                guard let peripheral = sessionContext.peripheral else {
                    assertionFailure("invalidCreateSessionContext \(sessionContext)")
                    throw AirBeamSessionCreatorError.invalidCreateSessionContext(sessionContext)
                }
                try measurementStreamStorage.createSession(session)
                AirBeam3Configurator(userAuthenticationSession: userAuthenticationSession,
                                     peripheral: peripheral).configureMobileSession(
                                        date: Date(),
                                        location: sessionContext.startingLocation ?? CLLocationCoordinate2D(latitude: 200, longitude: 200))
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
