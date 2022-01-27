// Created by Lunar on 13/09/2021.
//

import Foundation
import CoreLocation

final class AirBeamCellularSessionCreator: SessionCreator {
    enum AirBeamSessionCreatorError: Swift.Error {
        case invalidCreateSessionContext(CreateSessionContext)
    }
    private let userAuthenticationSession: UserAuthenticationSession
    private let measurementStreamStorage: MeasurementStreamStorage
    private let createSessionService: CreateSessionAPIService
    
    init(measurementStreamStorage: MeasurementStreamStorage, userAuthenticationSession: UserAuthenticationSession, baseUrl: BaseURLProvider) {
        self.measurementStreamStorage = measurementStreamStorage
        self.userAuthenticationSession = userAuthenticationSession
        self.createSessionService = CreateSessionAPIService(authorisationService: userAuthenticationSession,
                                                            baseUrlProvider: baseUrl)
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
                                                         completion: { [measurementStreamStorage, userAuthenticationSession] result in
                                                            #warning("TODO: https://github.com/HabitatMap/AirCastingiOS/pull/221/files#r707437312")
                                                            DispatchQueue.main.async {
                                                                switch result {
                                                                case .success(let output):
                                                                    measurementStreamStorage.accessStorage { storage in
                                                                        do {
                                                                            let sessionWithURL = session.withUrlLocation(output.location)
                                                                            try storage.createSession(sessionWithURL)
                                                                            try AirBeam3Configurator(userAuthenticationSession: userAuthenticationSession,
                                                                                                     peripheral: peripheral).configureFixedCellularSession(uuid: sessionUUID,
                                                                                                                                                           location: sessionContext.startingLocation ?? CLLocationCoordinate2D(latitude: 200, longitude: 200),
                                                                                                                                                           date: Date().currentUTCTimeZoneDate)
                                                                            Log.warning("Created fixed cellular session \(output)")
                                                                            completion(.success(()))
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
