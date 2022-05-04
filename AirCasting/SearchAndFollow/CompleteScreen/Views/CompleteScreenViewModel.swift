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
        // If the session already exists in the db change the button text to followed
        sessionStreams = .loading
        // TODO: remove force unwrapping
        thresholdsStore.getThresholdsValues(for: Self.getSensorName(session.stream.first!.sensorName)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let thresholdsValues):
                self.getMeasurementsAndDisplayData(thresholdsValues)
            case .failure(let error):
                switch error {
                case .noThresholdsFound:
                    self.getMeasurementsAndDisplayData(self.session.stream.first!.thresholdsValues)
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
            // TODO: remove after debugging
            let s = try externalSessionsStore.getExistingSession(uuid: session.uuid)
            Log.info("\(s.measurementStreams)")
        } catch {
            Log.error("FAILED: \(error)")
            self.alert = InAppAlerts.failedSessionDownloadAlert(dismiss: self.dismissView)
        }
        
    }
    
    private func dismissView() {
        exitRoute()
    }
    
    private func getMeasurementsAndDisplayData(_ thresholds: ThresholdsValue) {
        // TODO: remove force unwrapping
        let streams = [String(session.stream.first!.id)] // In the future this will be changed for Airbeam sessions, cause we will need to get other streams ids from backend
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
                    // Add measurements to session streams
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
