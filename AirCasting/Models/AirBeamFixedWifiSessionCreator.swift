// Created by Lunar on 11/05/2021.
//

import Foundation
import CoreLocation
import Resolver

final class AirBeamFixedWifiSessionCreator: SessionCreator {
    enum AirBeamSessionCreatorError: Swift.Error {
        case invalidCreateSessionContext(CreateSessionContext)
    }
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    @Injected private var uiStore: UIStorage
    private let createSessionService: CreateSessionAPIService
    
    convenience init() {
        self.init(createSessionService: CreateSessionAPIService())
    }
    
    init(createSessionService: CreateSessionAPIService) {
        self.createSessionService = createSessionService
    }
    
    func createSession(_ sessionContext: CreateSessionContext, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sessionType = sessionContext.sessionType,
              let sessionUUID = sessionContext.sessionUUID,
              let isIndoor = sessionContext.isIndoor
        else {
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
              let wifiSSID = sessionContext.wifiSSID,
              let wifiPassword = sessionContext.wifiPassword,
              let contribute = sessionContext.contribute
        else {
            assertionFailure("invalidCreateSessionContext \(sessionContext)")
            completion(.failure(AirBeamSessionCreatorError.invalidCreateSessionContext(sessionContext)))
            return
        }
        
        let params = CreateSessionApi.SessionParams(uuid: sessionUUID,
                                                    type: .fixed,
                                                    title: name,
                                                    tag_list: session.tags ?? "",
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
                                                         completion: { [measurementStreamStorage] result in
                                                            DispatchQueue.main.async {
                                                                switch result {
                                                                case .success(let output):
                                                                    measurementStreamStorage.accessStorage { storage in
                                                                        do {
                                                                            let sessionWithURL = session.withUrlLocation(output.location)
                                                                            try storage.createSession(sessionWithURL)
                                                                            self.uiStore.accessStorage({ storage in
                                                                                storage.giveHighestOrder(to: sessionWithURL.uuid)
                                                                            })
                                                                            Log.info("Created fixed Wifi session \(output)")
                                                                            // TODO: Potentially in both fixed session creators the logic for configuring AB could be performed before the session gets created.
                                                                            Resolver.resolve(AirBeamConfigurator.self, args: device)
                                                                                .configureFixedWifiSession(
                                                                                                        uuid: sessionUUID,
                                                                                                        location: sessionContext.startingLocation ?? CLLocationCoordinate2D(latitude: 200, longitude: 200),
                                                                                                        date: DateBuilder.getFakeUTCDate(),
                                                                                                        wifiSSID: wifiSSID,
                                                                                                        wifiPassword: wifiPassword) { result in
                                                                                                            switch result {
                                                                                                            case .success():
                                                                                                                Log.info("Successfully configured AB")
                                                                                                                completion(.success(()))
                                                                                                                return
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
                                                                    Log.warning("Failed to create fixed Wifi session \(error)")
                                                                    completion(.failure(error))
                                                                }
                                                            }
                                                         })
    }
}
