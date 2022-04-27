// Created by Lunar on 22/02/2022.
//

import Foundation
import SwiftUI
import Resolver

struct ExternalSessionStream: Identifiable {
    let id: Int
    let sensorName: String
    let sensorUnit: String
    let lastMeasurementValue: Double
    let color: Color
    let measurements: [Measurement]
    let thresholds: ThresholdsValue
    
    struct Measurement {
        let value: Double
        let time: Date
        let latitude: Double
        let longitude: Double
    }
}

struct ExternalSession {
    let uuid: String
    let provider: String
    let name: String
    let startTime: Date
    let endTime: Date
    let longitude: Double
    let latitude: Double
    let streams: [Stream]
    let sensorName: String
    
    // TODO: This will be implemented with the functionality for saving session to the database
    struct Stream {
    }
}

    struct PartialExternalSession {
        let uuid: String
        let provider: String
        let name: String
        let startTime: Date
        let endTime: Date
        let longitude: Double
        let latitude: Double
        let sensorName: String
        let stream: Stream
        let thresholdsValues: ThresholdsValue
        
        struct Stream {
            let id: Int
            let unitName: String
            let unitSymbol: String
            let sensorName: String
            let sensorPackageName: String
            let thresholdVeryLow: Int
            let thresholdLow: Int
            let thresholdMedium: Int
            let thresholdHigh: Int
            let thresholdVeryHigh: Int
        }
        
        static var mock: PartialExternalSession {
            let session =  self.init(uuid: "202411",
                                     provider: "OpenAir",
                                     name: "KAHULUI, MAUI",
                                     startTime: DateBuilder.getFakeUTCDate() - 60,
                                     endTime: DateBuilder.getFakeUTCDate(),
                                     longitude: 19.944544,
                                     latitude: 50.049683,
                                     sensorName: "OpenAQ-PM2.5",
                                     stream: Stream(id: 499130,
                                                           unitName: "microgram per cubic meter",
                                                           unitSymbol: "µg/m³",
                                                           sensorName: "OpenAQ-PM2.5",
                                                           sensorPackageName : "OpenAQ-PM2.5",
                                                           thresholdVeryLow : 0,
                                                           thresholdLow : 12,
                                                           thresholdMedium : 35,
                                                           thresholdHigh : 55,
                                                           thresholdVeryHigh : 150),
                                     thresholdsValues: ThresholdsValue(veryLow: 0, low: 5, medium: 8, high: 10, veryHigh: 12))
            // ...
            
            return session
        }
    }
    
class CompleteScreenViewModel: ObservableObject {
    @Published var selectedStream: Int?
    @Published var selectedStreamUnitSymbol: String?
    @Published var chartStartTime: Date?
    @Published var chartEndTime: Date?
    @Published var isMapSelected: Bool = true
    @Published var alert: AlertInfo?
    
    let sessionLongitude: Double
    let sessionLatitude: Double
    let sessionName: String
    let sessionStartTime: Date
    let sessionEndTime: Date
    let sensorType: String
    @Published var completeButtonEnabled: Bool = false
    @Published var sessionStreams: Loadable<[ExternalSessionStream]> = .loading {
        didSet {
            completeButtonEnabled = sessionStreams.isReady
        }
    }
    @Published var chartViewModel = SearchAndFollowChartViewModel()
    
    let exitRoute: () -> Void
    
    private let session: PartialExternalSession
    @Injected private var service: StreamDownloader
    @Injected private var thresholdsStore: ThresholdsStore
    @Injected private var singleSessionDownloader: SingleSessionDownloader
    @Injected private var externalSessionsStore: ExternalSessionsStore
    
    init(session: PartialExternalSession, exitRoute: @escaping () -> Void) {
        self.session = session
        sessionLongitude = session.longitude
        sessionLatitude = session.latitude
        sessionName = session.name
        sessionStartTime = session.startTime
        sessionEndTime = session.endTime
        sensorType = session.provider
        self.exitRoute = exitRoute
        reloadData()
    }
    
    private func reloadData() {
        sessionStreams = .loading
        thresholdsStore.getThresholdsValues(for: Self.getSensorName(session.sensorName)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let thresholdsValues):
                self.getMeasurementsAndDisplayData(thresholdsValues)
            case .failure(let error):
                switch error {
                case .noThresholdsFound:
                    self.getMeasurementsAndDisplayData(self.session.thresholdsValues)
                default:
                    Log.error("Failed to get threshold values: \(error)")
                    DispatchQueue.main.async {
                        self.alert = InAppAlerts.failedSessionDownloadAlert(dismiss: self.dismissView)
                    }
                }
            }
        }
    }
    
    func mapTapped() {
        isMapSelected.toggle()
    }
    
    func chartTapped() {
        isMapSelected.toggle()
    }
    
    func selectedStream(with id: Int) {
        selectedStream = id
    }
    
    func xMarkTapped() {
        exitRoute()
    }
    
    func confirmationButtonPressed() {
        do {
            try externalSessionsStore.createExternalSession(session: session)
            sessionStreams.get?.forEach({ stream in
                
            })
        } catch {
            Log.error("FAILED")
            self.alert = InAppAlerts.failedSessionDownloadAlert(dismiss: self.dismissView)
        }
    }
    
    private func dismissView() {
        exitRoute()
    }
    
    private func getMeasurementsAndDisplayData(_ thresholds: ThresholdsValue) {
        let streams = [String(session.streamID)] // In the future this will be changed for Airbeam sessions, cause we will need to get other streams ids from backend
        downloadMeasurements(streams: streams) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                Log.error("Failed to download session: \(error)")
                DispatchQueue.main.async {
                    self.alert = InAppAlerts.failedSessionDownloadAlert(dismiss: self.dismissView)
                }
            case .success(let downloadedStreams):
                DispatchQueue.main.async {
                    self.sessionStreams = .ready( downloadedStreams.map {
                        .init(id: $0.id,
                              sensorName: Self.getSensorName($0.sensorName),
                              sensorUnit: $0.sensorUnit,
                              lastMeasurementValue: $0.lastMeasurementValue,
                              color: thresholds.colorFor(value: $0.lastMeasurementValue),
                              measurements: $0.measurements.map({.init(value: $0.value, time: DateBuilder.getDateWithTimeIntervalSince1970(Double($0.time)), latitude: $0.latitude, longitude: $0.longitude)}), thresholds: thresholds)
                    })
                    if let stream = downloadedStreams.first {
                        self.selectedStream = stream.id
                        self.selectedStreamUnitSymbol = stream.sensorUnit
                        (self.chartStartTime, self.chartEndTime) = self.chartViewModel.generateEntries(with: stream.measurements.map({ SearchAndFollowChartViewModel.ChartMeasurement(value: $0.value, time: DateBuilder.getDateWithTimeIntervalSince1970(Double($0.time/1000))) }), thresholds: thresholds)
                    }
                }
            }
        }
    }
    
    private func downloadMeasurements(streams: [String],completion: @escaping (Result<[StreamWithMeasurements], Error>) -> Void) {
            var results: [Result<StreamWithMeasurements, Error>] = []
            let measurementsLimit = 60*24 // We want measurement from 24 hours
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
    
    private static func getSensorName(_ streamName: String) -> String {
        streamName
            .replacingOccurrences(of: ":", with: "-")
            .drop { $0 != "-" }
            .replacingOccurrences(of: "-", with: "")
    }
}
