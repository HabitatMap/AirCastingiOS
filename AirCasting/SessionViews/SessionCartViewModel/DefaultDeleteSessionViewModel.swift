// Created by Lunar on 16/07/2021.
//

import Foundation

class DefaultDeleteSessionViewModel: DeleteSessionViewModel {
    private let measurementStreamStorage: MeasurementStreamStorage
    private var session: SessionEntity
    private let streamRemover: StreamRemover
    @Published var showingConfirmationAlert: Bool = false
    
    var deleteEnabled: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    
    var streamOptions: [DeleteSessionOptionViewModel] {
        willSet {
            objectWillChange.send()
        }
    }
    
    private var streamsToDelete: [String] {
        var arrayOfContent = [String]()
        streamOptions.filter({ $0.isSelected }).forEach { option in
            guard let stream = session.allStreams?.first(where: { ($0.sensorName!.contains(option.title)) }) else { return }
            guard stream.sensorName != nil else { return }
            arrayOfContent.append(stream.sensorName!)
        }
        return arrayOfContent
    }
    
    init(session: SessionEntity, measurementStreamStorage: MeasurementStreamStorage, streamRemover: StreamRemover) {
        self.measurementStreamStorage = measurementStreamStorage
        self.session = session
        self.streamRemover = streamRemover
        
        var sessionStreams: [MeasurementStreamEntity] {
            return session.sortedStreams?.filter( {!$0.gotDeleted} ) ?? []
        }
        
        streamOptions = [.init(id: -1, title: Strings.DefaultDeleteSessionViewModel.all, isSelected: false, isEnabled: false)]
        showProperStreams(sessionStreams: sessionStreams)
    }
    
    func showConfirmationAlert() {
        showingConfirmationAlert = true
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
    
    func deleteSelected() {
        measurementStreamStorage.accessStorage { [self] storage in
            do {
                if self.streamOptions.first!.isSelected {
                    try storage.markSessionForDelete(self.session.uuid)
                } else {
                    try? storage.markStreamForDelete(session.uuid, sensorsName: streamsToDelete) {
                        processStreamDeleting()
                    }
                }
            } catch {
                Log.info("Error when deleting sessions/streams")
            }
        }
    }
    
    private func processStreamDeleting() {
        self.measurementStreamStorage.accessStorage { [self] storage in
            guard let sessionToPass = try? storage.getExistingSession(with: session.uuid) else { return }
            streamRemover.deleteStreams(session: sessionToPass) {
                try? storage.deleteStreams(session.uuid)
            }
        }
    }
    
    func didSelect(option: DeleteSessionOptionViewModel) {
        guard let index = streamOptions.firstIndex(where: { $0.id == option.id }) else {
            assertionFailure("Unknown option index")
            return
        }
        streamOptions[index].toggleSelection()
        
        if index == 0 {
            for i in streamOptions.indices {
                streamOptions[i].changeSelection(newSelected: streamOptions[0].isSelected)
            }
        } else {
            if streamOptions[index].isSelected == false && streamOptions[0].isSelected {
                streamOptions[0].isSelected = false
            }
            if streamOptions.dropFirst().allSatisfy({ $0.isSelected }) {
                streamOptions[0].isSelected = true
            }
        }
    }
}
