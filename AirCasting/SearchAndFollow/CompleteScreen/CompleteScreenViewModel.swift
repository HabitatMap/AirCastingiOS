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

protocol SearchSessionStreamsDownstream {
    func downloadSession(uuid: SessionUUID, completion: @escaping (Result<SearchSession, Error>) -> Void)
}

class SearchSessionStreamsDownstreamMock: SearchSessionStreamsDownstream {
    func downloadSession(uuid: SessionUUID, completion: @escaping (Result<SearchSession, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            completion(.success(.mock))
        }
    }
}

enum Loadable<T> {
    case loading
    case ready(T)
    
    var isReady: Bool {
        switch self {
        case .ready: return true
        case .loading: return false
        }
    }
    
    var get: T {
        switch self {
        case .loading: fatalError("variable not ready!")
        case .ready(let item): return item
        }
    }
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
    let sessionLongitude: Double
    let sessionLatitude: Double
    let sessionName: String
    let sessionStartTime: Date
    let sessionEndTime: Date
    let sensorType: String
    @Published var sessionStreams: Loadable<[SessionStreamViewModel]> = .loading
    @Published var chartViewModel: Loadable<SearchAndFollowChartViewModel> = .loading
    
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
        chartViewModel = .loading
        service.downloadSession(uuid: session.uuid) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error): break //TODO: Handle me
            case .success(let downloadedSession):
                self.sessionStreams = .ready(
                    downloadedSession.streams.map({
                        .init(id: $0.id,
                              sensorName: Self.showStreamName($0.sensorName),
                              lastMeasurementValue: $0.measurements.last?.value ?? 0)
                    })
                )
                self.chartViewModel = .ready(.init(stream: downloadedSession.streams.first))
                self.selectedStream = downloadedSession.streams.first?.id
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
