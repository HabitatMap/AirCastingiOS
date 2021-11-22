// Created by Lunar on 16/07/2021.
//

import Foundation

class DefaultDeleteSessionViewModel: DeleteSessionViewModel {
    let measurementStreamStorage: MeasurementStreamStorage
    var session: SessionEntity
    let streamRemover: StreamRemover
    
    var deleteEnabled: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    // It is variable because of the following scenario :
    // 1. Go to delete session scene
    // 2. Remove one of the streams on different device
    // 3. It should after sync it should get removed from the view
    
    var options: [DeleteSessionOptionViewModel] {
        willSet {
            objectWillChange.send()
        }
    }
    
    init(session: SessionEntity, measurementStreamStorage: MeasurementStreamStorage, streamRemover: StreamRemover) {
        
        self.measurementStreamStorage = measurementStreamStorage
        self.session = session
        self.streamRemover = streamRemover
        
        var sessionStreams: [MeasurementStreamEntity] {
            return session.sortedStreams?.filter( {!$0.gotDeleted} ) ?? []
        }
        
        options = [.init(id: -1, title: "All", isSelected: false, isEnabled: false)]
        showProperStreams(sessionStreams: sessionStreams)
    }
    
    func showProperStreams(sessionStreams: [MeasurementStreamEntity]) {
        for (id, stream) in sessionStreams.enumerated() {
            if var streamName = stream.sensorName {
                if streamName == Constants.SensorName.microphone {
                    options.append(.init(id: id, title: "dB", isSelected: false, isEnabled: false))
                } else {
                    streamName = streamName.components(separatedBy: "-")[1]
                    options.append(.init(id: id, title: streamName, isSelected: false, isEnabled: false))
                }
            }
        }
    }
    
    func collectStreamToDelete(streamsToDelete: inout [String]) {
        options.filter({ $0.isSelected }).forEach { option in
            guard let stream = session.allStreams?.first(where: { ($0.sensorName!.contains(option.title)) }) else { return }
            guard stream.sensorName != nil else { return }
            streamsToDelete.append(stream.sensorName!)
        }
    }
    
    func deleteSelected() {
        var streamsToDelete = [String]()
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                if self.options.first!.isSelected {
                    try storage.preapareSessionForDeletion(self.session.uuid)
                } else {
                    collectStreamToDelete(streamsToDelete: &streamsToDelete)
                    try? storage.preapareStreamForDeletion(session.uuid, sensorsName: streamsToDelete) {
                        processDeleting(streamsToDelete: &streamsToDelete)
                    }
                }
            } catch {
                Log.info("Error when deleting sessions/streams")
            }
        }
    }
    
    func processDeleting(streamsToDelete: inout [String]) {
        self.measurementStreamStorage.accessStorage { [self] storage in
            guard let sessionToPass = try? storage.getExistingSession(with: session.uuid) else { return }
            streamRemover.deleteStreams(client: URLSession.shared, session: sessionToPass) {
                try? storage.deleteStreams(session.uuid)
            }
        }
    }
    
    func didSelect(option: DeleteSessionOptionViewModel) {
        guard let index = options.firstIndex(where: { $0.id == option.id }) else {
            assertionFailure("Unknown option index")
            return
        }
        options[index].toggleSelection()
        
        if index == 0 {
            for i in options.indices {
                options[i].changeSelection(newSelected: options[0].isSelected)
            }
        } else {
            if options[index].isSelected == false && options[0].isSelected {
                options[0].isSelected = false
            }
            if options.dropFirst().allSatisfy({ $0.isSelected }) {
                options[0].isSelected = true
            }
        }
    }
}
