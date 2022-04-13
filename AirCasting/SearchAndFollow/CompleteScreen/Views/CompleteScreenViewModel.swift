// Created by Lunar on 22/02/2022.
//

import Foundation
import SwiftUI
import Resolver

struct SessionStreamViewModel: Identifiable {
    let id: Int
    let sensorName: String
    let lastMeasurementValue: Double
    let color: Color
    let measurements: [Measurement]
    
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

class CompleteScreenViewModel: ObservableObject {
    struct PartialExternalSession {
        let uuid: String
        let provider: String
        let name: String
        let startTime: Date
        let endTime: Date
        let longitude: Double
        let latitude: Double
        let sensorName: String
        
        static var mock: PartialExternalSession {
            let session =  self.init(uuid: "202411",
                                     provider: "OpenAir",
                                     name: "KAHULUI, MAUI",
                                     startTime: DateBuilder.getFakeUTCDate() - 60,
                                     endTime: DateBuilder.getFakeUTCDate(),
                                     longitude: 19.944544,
                                     latitude: 50.049683,
                                     sensorName: "OpenAQ-PM2.5")
            // ...
            
            return session
        }
    }
    
    @Published var selectedStream: Int?
    @Published var selectedStreamUnitSymbol: String?
    @Published var chartStartTime: Date?
    @Published var chartEndTime: Date?
    @Published var isMapSelected: Bool = true
    @Published var showAlert = false
    @Published var alert: AlertInfo?
    
    let sessionLongitude: Double
    let sessionLatitude: Double
    let sessionName: String
    let sessionStartTime: Date
    let sessionEndTime: Date
    let sensorType: String
    @Published var sessionStreams: Loadable<[SessionStreamViewModel]> = .loading
    @Published var chartViewModel = SearchAndFollowChartViewModel()
    
    private let session: PartialExternalSession
    private var service = DefaultStreamDownloader()
    private var isPresented: Binding<Bool>
    @Injected private var thresholdsStore: ThresholdsStore
    
    init(session: PartialExternalSession, isPresented: Binding<Bool>) {
        self.session = session
        sessionLongitude = session.longitude
        sessionLatitude = session.latitude
        sessionName = session.name
        sessionStartTime = session.startTime
        sessionEndTime = session.endTime
        sensorType = session.provider
        self.isPresented = isPresented
        reloadData()
    }
    
    private func reloadData() {
        sessionStreams = .loading
        thresholdsStore.getThresholdsValues(for: Self.getSensorName(session.sensorName)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let thresholdsValues):
                self.downloadMeasurements() { [weak self] result in
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
                                      lastMeasurementValue: $0.lastMeasurementValue,
                                      color: thresholdsValues.colorFor(value: $0.lastMeasurementValue),
                                      measurements: $0.measurements.map({.init(value: $0.value, time: DateBuilder.getDateWithTimeIntervalSince1970(Double($0.time)), latitude: $0.latitude, longitude: $0.longitude)}))
                            })
                            if let stream = downloadedStreams.first {
                                self.selectedStream = stream.id
                                self.selectedStreamUnitSymbol = stream.sensorUnit
                                (self.chartStartTime, self.chartEndTime) = self.chartViewModel.generateEntries(with: stream.measurements.map({ SearchAndFollowChartViewModel.ChartMeasurement(value: $0.value, time: DateBuilder.getDateWithTimeIntervalSince1970(Double($0.time))) }), thresholds: thresholdsValues)
                            }
                        }
                    }
                }
            case .failure(let error):
                Log.error("Failed to get threshold values: \(error)")
                DispatchQueue.main.async {
                    self.alert = InAppAlerts.failedSessionDownloadAlert(dismiss: self.dismissView)
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
        isPresented.wrappedValue = false
    }
    
    func dismissView() {
        isPresented.wrappedValue = false
    }
    
    private func downloadMeasurements(completion: @escaping (Result<[StreamWithMeasurementsDownstream], Error>) -> Void) {
            var results: [Result<StreamWithMeasurementsDownstream, Error>] = []
            let streams = ["499130"] // TODO: Get those streamIds from backend
            let group = DispatchGroup()
            streams.forEach { streamId in
                group.enter()
                self.service.downloadStreamWithMeasurements(id: streamId) { results.append($0); group.leave() }
            }
            group.notify(queue: .global()) {
                var allDownstreams = [StreamWithMeasurementsDownstream]()
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
