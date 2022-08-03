// Created by Lunar on 01/08/2022.
//

import Foundation

enum ThresholdAlertFrequency {
    case oneHour
    case twentyFourHours
}

class ThresholdAlertSheetViewModel: ObservableObject {
    @Published var isOn = false
    private var session: Sessionable
    private let apiClient: ShareSessionAPIServices
    
    @Published var streamOptions: [StreamOption] = []
    @Published var frequency = ThresholdAlertFrequency.oneHour
    
    struct StreamOption: Identifiable {
        var id: Int
        var streamName: String
        var shortStreamName: String
        var isOn: Bool
        var thresholdValue: String
    }
    
    init(session: Sessionable, apiClient: ShareSessionAPIServices) {
        self.session = session
        self.apiClient = apiClient
        showProperStreams()
    }
    
    func confirmationButtonPressed() {}
    
    func changeIsOn(of id: Int, to value: Bool) {
        guard let streamOptionId = streamOptions.first(where: { $0.id == id })?.id else { return }
        streamOptions[streamOptionId].isOn = value
        Log.info("## \(streamOptions[streamOptionId])")
    }
    
    func changeThreshold(of id: Int, to value: String) {
        guard let streamOptionId = streamOptions.first(where: { $0.id == id })?.id else { return }
        streamOptions[streamOptionId].thresholdValue = value
        Log.info("## \(streamOptions[streamOptionId])")
    }
    
    func save() {
        
    }
    
    private func showProperStreams() {
        let sessionStreams = session.sortedStreams.filter( {!$0.gotDeleted} )
        streamOptions = []
        var i = 0
        sessionStreams.forEach { stream in
            guard let name = stream.sensorName else { return }
            streamOptions.append(StreamOption(id: i, streamName: name, shortStreamName: shorten(name), isOn: false, thresholdValue: ""))
            i+=1
        }
    }
    
    func shorten(_ streamName: String) -> String {
        String(streamName.replacingOccurrences(of: ":", with: "-").split(separator: "-").last ?? "")
    }
}
