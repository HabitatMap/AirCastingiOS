// Created by Lunar on 04/05/2022.
//

import Foundation
import Resolver

protocol SearchAndFollowCompleteScreenService {
    func createExternalSession(from session: PartialExternalSession, with downloadedStreamsWithMeasurements: [StreamWithMeasurements]) -> ExternalSessionWithStreamsAndMeasurements
    func downloadMeasurements(streamsIds: [Int], completion: @escaping (Result<[StreamWithMeasurements], Error>) -> Void)
    func followSession(session: ExternalSessionWithStreamsAndMeasurements, completion: @escaping (Result<Void, Error>) -> Void)
}

struct DefaultSearchAndFollowCompleteScreenService: SearchAndFollowCompleteScreenService {
    @Injected private var service: StreamDownloader
    @Injected private var externalSessionsStore: ExternalSessionsStore
    
    func createExternalSession(from session: PartialExternalSession, with downloadedStreamsWithMeasurements: [StreamWithMeasurements]) -> ExternalSessionWithStreamsAndMeasurements {
        .init(uuid: session.uuid,
              provider: session.provider,
              name: session.name,
              startTime: session.startTime,
              endTime: session.endTime,
              longitude: session.longitude,
              latitude: session.latitude,
              streams: session.stream.compactMap { stream in
            
            guard let downloadedStream = downloadedStreamsWithMeasurements.first(where: { $0.sensorName == stream.sensorName }) else { return nil }
            
            let measurements = downloadedStream.measurements
            return .init(id: stream.id,
                         unitName: stream.unitName,
                         unitSymbol: stream.unitSymbol,
                         measurementShortType: stream.measurementShortType,
                         measurementType: stream.measurementType,
                         sensorName: stream.sensorName,
                         sensorPackageName: stream.sensorPackageName,
                         thresholdsValues: stream.thresholdsValues,
                         measurements: measurements.map {.init(value: $0.value, time: DateBuilder.getDateWithTimeIntervalSince1970(Double($0.time/1000)), latitude: $0.latitude, longitude: $0.longitude)})
        })
    }
    
    func downloadMeasurements(streamsIds: [Int], completion: @escaping (Result<[StreamWithMeasurements], Error>) -> Void) {
        guard !streamsIds.isEmpty else {
            completion(.failure(CompletionScreenError.noStreams))
            return
        }
        var results: [Result<StreamWithMeasurements, Error>] = []
        let measurementsLimit = 60*24 // We want measurements from 24 hours
        let group = DispatchGroup()
        streamsIds.forEach { streamId in
            group.enter()
            self.service.downloadStreamWithMeasurements(id: streamId, measurementsLimit: measurementsLimit) { results.append($0); group.leave() }
        }
        group.notify(queue: .global()) {
            do { try completion(.success(results.map { try $0.get() })) }
            catch { completion(.failure(error)) }
        }
    }
    
    func followSession(session: ExternalSessionWithStreamsAndMeasurements, completion: @escaping (Result<Void, Error>) -> Void) {
        externalSessionsStore.createExternalSession(session: session, completion: completion)
    }
}