// Created by Lunar on 22/02/2022.
//

import Foundation
import SwiftUI

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
    let sessionStreams: [SearchSession.SearchSessionStream]
    @Published var streamForChart: SearchSession.SearchSessionStream?
    
    init(session: SearchSession) {
        self.session = session
        sessionLongitude = session.longitude
        sessionLatitude = session.latitude
        sessionName = session.name
        sessionStartTime = session.startTime
        sessionEndTime = session.endTime
        sessionStreams = session.streams
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
}
