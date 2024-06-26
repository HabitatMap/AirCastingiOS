// Created by Lunar on 13/09/2021.
//

import Foundation
import CoreLocation
import Resolver

final class AirBeamCellularSessionCreator: SessionCreator {
    enum AirBeamSessionCreatorError: Swift.Error {
        case invalidCreateSessionContext(CreateSessionContext)
    }
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    @Injected private var sessionStorage: SessionCreatingStorage
    @Injected private var uiStore: UIStorage
    private let createSessionService: CreateSessionAPIService
    
    init() {
        self.createSessionService = CreateSessionAPIService()
    }
    
    func createSession(_ sessionContext: CreateSessionContext, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionType = sessionContext.sessionType,
              let sessionUUID = sessionContext.sessionUUID,
              let deviceType = sessionContext.deviceType,
              let isIndoor = sessionContext.isIndoor else {
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
                              startTime: DateBuilder.getFakeUTCDate(),
                              followedAt: DateBuilder.getFakeUTCDate(),
                              isIndoor: isIndoor,
                              tags: sessionContext.sessionTags)
        
        // if session is fixed: create an empty session on server,
        // then send AB auth data to connect to web session and data needed to start recording
        guard let name = session.name,
              let startTime = session.startTime,
              let device = sessionContext.device,
              let contribute = sessionContext.contribute else {
            assertionFailure("invalidCreateSessionContext \(sessionContext)")
            completion(.failure(AirBeamSessionCreatorError.invalidCreateSessionContext(sessionContext)))
            return
        }
        
        let params = CreateSessionApi.SessionParams(uuid: sessionUUID,
                                                    type: .fixed,
                                                    title: name,
                                                    tag_list: sessionContext.sessionTags ?? "",
                                                    start_time: startTime,
                                                    end_time: startTime,
                                                    contribute: contribute,
                                                    is_indoor: isIndoor,
                                                    notes: [],
                                                    version: 0,
                                                    streams: [:],
                                                    latitude: sessionContext.startingLocation?.latitude,
                                                    longitude: sessionContext.startingLocation?.longitude)
        
        createSessionService.createEmptyFixedWifiSession(input: .init(session: params,
                                                                      compression: true),
                                                         completion: { [sessionStorage] result in
                                                            #warning("TODO: https://github.com/HabitatMap/AirCastingiOS/pull/221/files#r707437312")
                                                            DispatchQueue.main.async {
                                                                switch result {
                                                                case .success(let output):
                                                                    sessionStorage.accessStorage { storage in
                                                                        do {
                                                                            let sessionWithURL = session.withUrlLocation(output.location)
                                                                            try storage.createSession(sessionWithURL)
                                                                            self.uiStore.accessStorage({ storage in
                                                                                storage.giveHighestOrder(to: sessionWithURL.uuid)
                                                                            })
                                                                            Log.info("Created fixed cellular session \(output)")
                                                                            Resolver.resolve(AirBeamConfigurator.self, args: device)
                                                                                .configureFixedCellularSession(uuid: sessionUUID,
                                                                                                               location: sessionContext.startingLocation ?? CLLocationCoordinate2D(latitude: 200, longitude: 200),
                                                                                                               date: DateBuilder.getFakeUTCDate()) { result in
                                                                                    switch result {
                                                                                    case .success():
                                                                                        Log.info("Successfully configured AB")
                                                                                        completion(.success(()))
                                                                                    case .failure(let error):
                                                                                        Log.error("Failed to configure AB: \(error)")
                                                                                        completion(.failure(error))
                                                                                    }
                                                                                }
                                                                        } catch {
                                                                            completion(.failure(error))
                                                                        }
                                                                    }
                                                                case .failure(let error):
                                                                    Log.warning("Failed to create fixed cellular session \(error)")
                                                                    completion(.failure(error))
                                                                }
                                                            }
                                                         })
    }
}
