// Created by Lunar on 22/02/2022.
//

import Foundation
import SwiftUI

struct SessionStreamViewModel: Identifiable {
    let id: Int
    let sensorName: String
    let lastMeasurementValue: Double
}

class CompleteScreenViewModel: ObservableObject {
    private let session: SearchSession
    @Published var selectedStream: Int?
    @Published var isMapSelected: Bool = true
    let sessionLongitude: Double
    let sessionLatitude: Double
    let sessionName: String
    let sessionStartTime: Date
    let sessionEndTime: Date
    let sensorType: String
    let sessionStreams: [SessionStreamViewModel]
    @Published var streamForChart: SearchSession.SearchSessionStream?
    
    init(session: SearchSession) {
        self.session = session
        sessionLongitude = session.longitude
        sessionLatitude = session.latitude
        sessionName = session.name
        sessionStartTime = session.startTime
        sessionEndTime = session.endTime
        sessionStreams = session.streams.map({ .init(id: $0.id, sensorName: Self.showStreamName($0.sensorName), lastMeasurementValue: $0.measurements.last?.value ?? 0) })
        selectedStream = session.streams.first?.id
        streamForChart = session.streams.first
        sensorType = "OpenAir"
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
