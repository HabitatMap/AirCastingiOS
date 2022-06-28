// Created by Lunar on 04/05/2022.
//

import Foundation
import Resolver

protocol SearchAndFollowCompleteScreenService {
    func createExternalSession(from session: PartialExternalSession, with downloadedStreamsWithMeasurements: [MeasurementsDownloaderResultModel.Stream]) -> ExternalSessionWithStreamsAndMeasurements
    func followSession(session: ExternalSessionWithStreamsAndMeasurements, completion: @escaping (Result<Void, Error>) -> Void)
    func unfollowSession(sessionUUID: SessionUUID, completion: @escaping (Result<Void, Error>) -> Void)
}

struct DefaultSearchAndFollowCompleteScreenService: SearchAndFollowCompleteScreenService {
    @Injected private var service: StreamDownloader
    @Injected private var externalSessionsStore: ExternalSessionsStore
    @Injected private var uiStore: UIStorage
    
    func createExternalSession(from session: PartialExternalSession, with downloadedStreamsWithMeasurements: [MeasurementsDownloaderResultModel.Stream]) -> ExternalSessionWithStreamsAndMeasurements {
        .init(uuid: session.uuid,
              provider: session.provider,
              name: session.name,
              startTime: session.startTime,
              endTime: session.endTime,
              longitude: session.longitude,
              latitude: session.latitude,
              streams: downloadedStreamsWithMeasurements.map({ stream in
            
            let measurements = stream.measurements
            return .init(id: stream.streamId,
                         unitName: stream.unitName,
                         unitSymbol: stream.sensorUnit,
                         measurementShortType: stream.measurementShortType,
                         measurementType: stream.measurementType,
                         sensorName: stream.sensorName,
                         sensorPackageName: stream.sensorName,
                         thresholdsValues: .init(veryLow: stream.thresholdVeryLow,
                                                 low: stream.thresholdLow,
                                                 medium: stream.thresholdMedium,
                                                 high: stream.thresholdHigh,
                                                 veryHigh: stream.thresholdVeryHigh),
                         measurements: measurements.map {.init(value: $0.value,
                                                               time: DateBuilder.getDateWithTimeIntervalSince1970(Double($0.time/1000)),
                                                               latitude: $0.latitude,
                                                               longitude: $0.longitude)})
        })
        )
    }
    
    func followSession(session: ExternalSessionWithStreamsAndMeasurements, completion: @escaping (Result<Void, Error>) -> Void) {
        externalSessionsStore.createExternalSession(session: session) { [uiStore] in
            switch $0 {
            case .success:
                uiStore.accessStorage { store in
                    store.giveHighestOrder(to: session.uuid)
                    do {
                        try store.cardStateToggle(for: session.uuid)
                    } catch {
                        Log.error("Changing card state failed: \(error)")
                    }
                    completion(.success(()))
                }
            case .failure(let error): completion(.failure(error))
            }
        }
    }
    
    func unfollowSession(sessionUUID: SessionUUID, completion: @escaping (Result<Void, Error>) -> Void) {
        externalSessionsStore.deleteSession(uuid: sessionUUID) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
                Log.error("Failing to delete External Session: \(error)")
            }
        }
    }
}
