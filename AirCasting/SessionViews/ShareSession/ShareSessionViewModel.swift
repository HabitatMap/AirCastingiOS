// Created by Lunar on 16/12/2021.
//

import Foundation

protocol ShareSessionViewModel: ObservableObject {
    var streamOptions: [ShareSessionStreamOptionViewModel] {get set}
    func didSelect(option: ShareSessionStreamOptionViewModel)
}

class DefaultShareSessionViewModel: ShareSessionViewModel {
    var itemsForSharing: [String] = ["www.google.com"]
    private var session: SessionEntity
    
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
        toggleSelection(at: index)
        Log.info("##\(streamOptions)")
    }
    
    private func showProperStreams(sessionStreams: [MeasurementStreamEntity]) {
        for (id, stream) in sessionStreams.enumerated() {
            if var streamName = stream.sensorName {
                if streamName == Constants.SensorName.microphone {
                    streamOptions.append(.init(id: id, title: "dB", isSelected: false, isEnabled: false))
                } else {
                    streamName = streamName.components(separatedBy: "-")[1]
                    streamOptions.append(.init(id: id, title: streamName, isSelected: false, isEnabled: false))
                }
            }
        }
    }
    
    private func toggleSelection(at index: Int) {
        guard index < streamOptions.count else { return }
        
        if !streamOptions[index].isSelected {
            for i in streamOptions.indices {
                streamOptions[i].changeSelection(newSelected: false)
            }
        }
        streamOptions[index].toggleSelection()
    }
}
