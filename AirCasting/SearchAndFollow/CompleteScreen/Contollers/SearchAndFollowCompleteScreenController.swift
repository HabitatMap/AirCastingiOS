// Created by Lunar on 04/05/2022.
//

import Foundation
import Resolver

protocol SearchAndFollowCompleteScreenController {
    func createExternalSession(from session: PartialExternalSession,with downloadedStreamsWithMeasurements: [StreamWithMeasurements]) -> ExternalSessionWithStreamsAndMeasurements
    func downloadMeasurements(streams: [Int], completion: @escaping (Result<[StreamWithMeasurements], Error>) -> Void)
}

struct DefaultSearchAndFollowCompleteScreenController: SearchAndFollowCompleteScreenController {
    @Injected private var service: StreamDownloader
    
    func createExternalSession(from session: PartialExternalSession,with downloadedStreamsWithMeasurements: [StreamWithMeasurements]) -> ExternalSessionWithStreamsAndMeasurements {
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
                         thresholdVeryLow: stream.thresholdsValues.veryLow,
                         thresholdLow: stream.thresholdsValues.low,
                         thresholdMedium: stream.thresholdsValues.medium,
                         thresholdHigh: stream.thresholdsValues.high,
                         thresholdVeryHigh: stream.thresholdsValues.veryHigh,
                         thresholdsValues: stream.thresholdsValues,
                         measurements: measurements.map {.init(value: $0.value, time: DateBuilder.getDateWithTimeIntervalSince1970(Double($0.time/1000)), latitude: $0.latitude, longitude: $0.longitude)})
        })
    }
    
    func downloadMeasurements(streams: [Int], completion: @escaping (Result<[StreamWithMeasurements], Error>) -> Void) {
        guard !streams.isEmpty else {
            completion(.failure(CompletionScreenError.noStreams))
            return
        }
        var results: [Result<StreamWithMeasurements, Error>] = []
        let measurementsLimit = 60*24 // We want measurements from 24 hours
        let group = DispatchGroup()
        streams.forEach { streamId in
            group.enter()
            self.service.downloadStreamWithMeasurements(id: streamId, measurementsLimit: measurementsLimit) { results.append($0); group.leave() }
        }
        group.notify(queue: .global()) {
            var allDownstreams = [StreamWithMeasurements]()
            for result in results {
                do {
                    allDownstreams.append(try result.get())
                } catch {
                    completion(.failure(error))
                    return
                }
            }
            completion(.success(allDownstreams))
        }
    }
}
