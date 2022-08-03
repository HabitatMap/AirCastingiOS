// Created by Lunar on 01/08/2022.
//

import Foundation

class ThresholdAlertSheetViewModel: ObservableObject {
    @Published var isOn = false
    private let exitRoute: (ShareSessionResult) -> Void
    private var session: Sessionable
    private let apiClient: ShareSessionAPIServices
    private lazy var selectedStream = streamOptions.first
    
    var streamOptions: [ShareSessionStreamOptionViewModel] {
        willSet {
            objectWillChange.send()
        }
    }
    
    init(session: SessionEntity, apiClient: ShareSessionAPIServices, exitRoute: @escaping (ShareSessionResult) -> Void) {
        self.session = session
        self.exitRoute = exitRoute
        self.apiClient = apiClient
        
        var sessionStreams: [MeasurementStreamEntity] {
            return session.sortedStreams.filter( {!$0.gotDeleted} )
        }
        
        streamOptions = []
        showProperStreams(sessionStreams: sessionStreams)
    }
    
    func didSelect(option: ShareSessionStreamOptionViewModel) {
        guard let index = streamOptions.firstIndex(where: { $0.id == option.id }) else {
            assertionFailure("Unknown option index")
            return
        }
        
        if !streamOptions[index].isSelected {
            for i in streamOptions.indices {
                streamOptions[i].changeSelection(newSelected: false)
            }
            streamOptions[index].toggleSelection()
            selectedStream = streamOptions[index]
        }
    }
    
    func confirmationButtonPressed() {}
    
    private func showProperStreams(sessionStreams: [MeasurementStreamEntity]) {
        var sensorName: String
        
        for (id, stream) in sessionStreams.enumerated() {
            if let streamName = stream.sensorName {
                if streamName == Constants.SensorName.microphone {
                    streamOptions.append(.init(id: id, title: "dB", streamName: Constants.SensorName.microphone, isSelected: false, isEnabled: false))
                } else {
                    let sensorNameComponents = streamName.components(separatedBy: "-")
                    if sensorNameComponents.count == 2 {
                        sensorName = streamName.components(separatedBy: "-")[1]
                    } else {
                        Log.warning("Received unexpected stream name format from server")
                        sensorName = streamName
                    }
                    streamOptions.append(.init(id: id, title: sensorName, streamName: streamName, isSelected: false, isEnabled: false))
                }
            }
        }
        if !streamOptions.isEmpty {
            streamOptions[0].toggleSelection()
        }
    }
}
