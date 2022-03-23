// Created by Lunar on 22/02/2022.
//

import Foundation
import SwiftUI
import Resolver

struct SessionStreamViewModel: Identifiable {
    let id: Int
    let sensorName: String
    let lastMeasurementValue: Double
}

struct SearchSessionResult {
    let uuid: SessionUUID
    let name: String
    let startTime: Date
    let endTime: Date
    let longitude: Double
    let latitude: Double
    
    static var mock: SearchSessionResult {
        let session =  self.init(uuid: .init(rawValue: "ASD")!,
                                 name: "Mock Session",
                                 startTime: DateBuilder.getFakeUTCDate() - 60,
                                 endTime: DateBuilder.getFakeUTCDate(),
                                 longitude: 19.944544,
                                 latitude: 50.049683)
        // ...
                
        return session
    }
}

class CompleteScreenViewModel: ObservableObject {
    @Published var selectedStream: Int?
    @Published var isMapSelected: Bool = true
    @Published var alert: AlertInfo?
    
    let sessionLongitude: Double
    let sessionLatitude: Double
    let sessionName: String
    let sessionStartTime: Date
    let sessionEndTime: Date
    let sensorType: String
    @Published var sessionStreams: Loadable<[SessionStreamViewModel]> = .loading
    @Published var chartViewModel = SearchAndFollowChartViewModel(stream: nil)
    
    private let session: SearchSessionResult
    @Injected private var service: SearchSessionStreamsDownstream
    
    init(session: SearchSessionResult) {
        self.session = session
        sessionLongitude = session.longitude
        sessionLatitude = session.latitude
        sessionName = session.name
        sessionStartTime = session.startTime
        sessionEndTime = session.endTime
        sensorType = "OpenAir"
        reloadData()
    }
    
    private func reloadData() {
        sessionStreams = .loading
        service.downloadSession(uuid: session.uuid) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                Log.error("Failed to download session: \(error)")
                self.alert = InAppAlerts.failedSessionDownloadAlert()
            case .success(let downloadedSession):
                self.sessionStreams = .ready(
                    downloadedSession.streams.map({
                        .init(id: $0.id,
                              sensorName: Self.showStreamName($0.sensorName),
                              lastMeasurementValue: $0.measurements.last?.value ?? 0)
                    })
                )
                self.selectedStream = downloadedSession.streams.first?.id
                if let stream = downloadedSession.streams.first {
                    self.chartViewModel.setStream(to: stream)
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
    
    private static func showStreamName(_ streamName: String) -> String {
        streamName
            .replacingOccurrences(of: ":", with: "-")
            .drop { $0 != "-" }
            .replacingOccurrences(of: "-", with: "")
    }
}
