// Created by Lunar on 16/12/2021.
//

import Foundation

protocol ShareSessionViewModel: ObservableObject {
    var streamOptions: [ShareSessionStreamOptionViewModel] {get set}
    func didSelect(option: ShareSessionStreamOptionViewModel)
    func getSharingLink() -> URL?
}

class DefaultShareSessionViewModel: ShareSessionViewModel {
    private var session: SessionEntity
    private lazy var selectedStream = streamOptions.first
    
    var streamOptions: [ShareSessionStreamOptionViewModel] {
        willSet {
            objectWillChange.send()
        }
    }
    
    init(session: SessionEntity) {
        self.session = session
        
        var sessionStreams: [MeasurementStreamEntity] {
            return session.sortedStreams?.filter( {!$0.gotDeleted} ) ?? []
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
    
    func getSharingLink() -> URL? {
        guard let sessionURL = session.urlLocation,
              var components = URLComponents(string: sessionURL)
        else {
            //TODO: add alert to try again
            return nil
        }

        components.queryItems = [URLQueryItem(name: "sensor_name", value: selectedStream?.streamName)]
        
        guard let url = components.url else {
            Log.error("Coudn't compose url for this stream")
            return nil
        }
        
        return url
    }
    
    private func showProperStreams(sessionStreams: [MeasurementStreamEntity]) {
        for (id, stream) in sessionStreams.enumerated() {
            if let streamName = stream.sensorName {
                if streamName == Constants.SensorName.microphone {
                    streamOptions.append(.init(id: id, title: "dB", streamName: Constants.SensorName.microphone, isSelected: false, isEnabled: false))
                } else {
                    let sensorName = streamName.components(separatedBy: "-")[1]
                    streamOptions.append(.init(id: id, title: sensorName, streamName: streamName, isSelected: false, isEnabled: false))
                }
            }
        }
        if !streamOptions.isEmpty {
            streamOptions[0].toggleSelection()
        }
    }
}
