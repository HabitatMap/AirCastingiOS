// Created by Lunar on 15/05/2022.
//

import Foundation
import CoreLocation
import Resolver

protocol LocationService {
    func getCurrentLocation() throws -> CLLocationCoordinate2D?
}

class DecibelMeasurementSaveable: MeasurementSaveable {
    private let locationService: LocationService
    private let session: Session
    private var databasePrepared: Bool = false
    @Injected private var persistence: MeasurementStreamStorage
    
    enum DecibelMeasurementSaveableError: Error {
        case streamNotFound
    }
    
    init(session: Session, locationService: LocationService) {
        self.session = session
        self.locationService = locationService
        prepareData { result in
            switch result {
            case .success: self.databasePrepared = true
            case .failure(let error): Log.error("Couldn't prepare database: \(error)")
            }
        }
    }
    
    func saveMeasurement(_ value: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        guard databasePrepared else { return }
        do {
            let location = session.locationless ? nil : try locationService.getCurrentLocation()
            
            persistence.accessStorage { [weak self] storage in
                do {
                    guard let session = self?.session else { return }
                    guard let streamID = try storage.existingMeasurementStream(session.uuid, name: Constants.SensorName.microphone) else {
                        throw DecibelMeasurementSaveableError.streamNotFound
                    }
                    try storage.addMeasurementValue(value, at: location, toStreamWithID: streamID)
                } catch {
                    Log.error("Failed sampling measurement: \(error)")
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    private func prepareData(completion: @escaping (Result<Void, Error>) -> Void) {
        let stream = MeasurementStream(id: nil,
                                       sensorName: Constants.SensorName.microphone,
                                       sensorPackageName: "Builtin",
                                       measurementType: "Sound Level",
                                       measurementShortType: "db",
                                       unitName: "decibels",
                                       unitSymbol: "dB",
                                       thresholdVeryHigh: 100,
                                       thresholdHigh: 80,
                                       thresholdMedium: 70,
                                       thresholdLow: 60,
                                       thresholdVeryLow: 20)
        
        persistence.accessStorage { [weak self] storage in
            do {
                guard let self = self else { return }
                _ = try storage.createSessionAndMeasurementStream(self.session, stream)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
