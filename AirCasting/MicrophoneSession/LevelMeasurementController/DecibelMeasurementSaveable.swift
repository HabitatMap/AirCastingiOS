// Created by Lunar on 15/05/2022.
//

import Foundation
import Resolver

final class DecibelMeasurementSaveable: MeasurementSaveable {
    private let session: Session
    private var databasePrepared: Bool = false
    @Injected private var persistence: MobileSessionRecordingStorage
    @Injected private var uiStorage: UIStorage
    @Injected private var locationService: LocationService
    
    enum DecibelMeasurementSaveableError: Error {
        case streamNotFound
    }
    
    init(session: Session) {
        self.session = session
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
                    try storage.addMeasurementValue(value, at: location, toStreamWithID: streamID, on: DateBuilder.getRawDate().currentUTCTimeZoneDate)
                    guard session.status != .RECORDING else { return }
                    try storage.updateSessionStatus(.RECORDING, for: session.uuid)
                } catch {
                    Log.error("Failed sampling measurement: \(error)")
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func handleInterruption() {
        persistence.accessStorage { [weak self] storage in
            guard let self = self else { return }
            do {
                try storage.updateSessionStatus(.DISCONNECTED, for: self.session.uuid)
            } catch {
                Log.error("Couldn't disconnect \(self.session.name ?? "Unknown") [\(self.session.uuid)]! \(error.localizedDescription)")
            }
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
                try storage.createSessionAndMeasurementStream(self.session, stream)
                self.uiStorage.accessStorage { storage in
                    do {
                        try storage.switchCardExpanded(to: true, sessionUUID: self.session.uuid)
                    } catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
