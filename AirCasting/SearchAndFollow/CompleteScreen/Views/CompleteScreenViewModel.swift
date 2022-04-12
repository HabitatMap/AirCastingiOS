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
}

struct SearchSessionResult {
    let id: String
    let name: String
    let startTime: Date
    let endTime: Date
    let longitude: Double
    let latitude: Double
    let streamId: String
    let sensorName: String
    
    static var mock: SearchSessionResult {
        let session =  self.init(id: "202411",
                                 name: "KAHULUI, MAUI",
                                 startTime: DateBuilder.getFakeUTCDate() - 60,
                                 endTime: DateBuilder.getFakeUTCDate(),
                                 longitude: 19.944544,
                                 latitude: 50.049683,
                                 streamId: "499130",
                                 sensorName: "OpenAQ-PM2.5")
        // ...
        
        return session
    }
}

class CompleteScreenViewModel: ObservableObject {
    @Published var selectedStream: Int?
    @Published var selectedStreamSymbol: String?
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
    private var streamId: String
    @Published var sessionStreams: Loadable<[SessionStreamViewModel]> = .loading
    @Published var chartViewModel = SearchAndFollowChartViewModel()
    
    private let session: SearchSessionResult
    private var service = DefaultStreamDownloader()
    @Injected private var thresholdsStore: ThresholdsStore
    
    init(session: SearchSessionResult) {
        self.session = session
        sessionLongitude = session.longitude
        sessionLatitude = session.latitude
        sessionName = session.name
        sessionStartTime = session.startTime
        sessionEndTime = session.endTime
        sensorType = "OpenAir"
        streamId = session.streamId
        reloadData()
    }
    
    private func reloadData() {
        sessionStreams = .loading
        thresholdsStore.getThresholdsValues(for: Self.getSensorName(session.sensorName)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let thresholdsValues):
                self.service.downloadStreamWithMeasurements(id: self.streamId) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .failure(let error):
                        Log.error("Failed to download session: \(error)")
                        DispatchQueue.main.async {
                            self.alert = InAppAlerts.failedSessionDownloadAlert()
                        }
                    case .success(let downloadedStream):
                        DispatchQueue.main.async {
                            self.sessionStreams = .ready(
                                [.init(id: downloadedStream.id,
                                       sensorName: Self.getSensorName(downloadedStream.sensorName),
                                       lastMeasurementValue: downloadedStream.lastMeasurementValue,
                                       color: thresholdsValues.colorFor(value: downloadedStream.lastMeasurementValue))])
                            self.selectedStream = downloadedStream.id
                            self.chartViewModel.generateEntries(with: downloadedStream.measurements.map(\.value), thresholds: thresholdsValues)
                        }
                    }
                }
            case .failure(let error):
                Log.error("Failed to get threshold values: \(error)")
                DispatchQueue.main.async {
                    self.alert = InAppAlerts.failedSessionDownloadAlert()
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
    
    private static func getSensorName(_ streamName: String) -> String {
        streamName
            .replacingOccurrences(of: ":", with: "-")
            .drop { $0 != "-" }
            .replacingOccurrences(of: "-", with: "")
    }
}
