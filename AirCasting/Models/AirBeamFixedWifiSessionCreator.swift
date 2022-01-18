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
    private let createSessionService: CreateSessionAPIService
    
    convenience init() {
        self.init(createSessionService: CreateSessionAPIService())
    }
    
    init(createSessionService: CreateSessionAPIService) {
        self.createSessionService = createSessionService
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
                              startTime: Date().currentUTCTimeZoneDate,
                              followedAt: Date().currentUTCTimeZoneDate,
                              tags: sessionContext.sessionTags)
        
        // if session is fixed: create an empty session on server,
        // then send AB auth data to connect to web session and data needed to start recording
        guard let name = session.name,
              let startTime = session.startTime,
              let peripheral = sessionContext.peripheral,
              let wifiSSID = sessionContext.wifiSSID,
              let wifiPassword = sessionContext.wifiPassword,
              let contribute = sessionContext.contribute,
              let isIndoor = sessionContext.isIndoor else {
            assertionFailure("invalidCreateSessionContext \(sessionContext)")
            completion(.failure(AirBeamSessionCreatorError.invalidCreateSessionContext(sessionContext)))
            return
        }
        
        #warning("TODO: change mocked data -->  notes")
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
                                                         completion: { [measurementStreamStorage, userAuthenticationSession] result in
                                                            DispatchQueue.main.async {
                                                                switch result {
                                                                case .success(let output):
                                                                    measurementStreamStorage.accessStorage { storage in
                                                                        do {
                                                                            try storage.createSession(session)
                                                                            try AirBeam3Configurator(peripheral: peripheral).configureFixedWifiSession(
                                                                                                        uuid: sessionUUID,
                                                                                                        location: sessionContext.startingLocation ?? CLLocationCoordinate2D(latitude: 200, longitude: 200),
                                                                                                        date: Date().currentUTCTimeZoneDate,
                                                                                                        wifiSSID: wifiSSID,
                                                                                                        wifiPassword: wifiPassword)
                                                                            Log.warning("Created fixed Wifi session \(output)")
                                                                            completion(.success(()))
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
