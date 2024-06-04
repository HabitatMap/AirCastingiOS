// Created by Lunar on 16/07/2021.
//

import Foundation
import Combine
import Resolver

class DefaultDeleteSessionViewModel: DeleteSessionViewModel {
    @Injected private var deletingStorage: SessionDeletingStorage
    private var session: SessionEntity
    @Injected private var streamRemover: SessionUpdateService
    @Injected private var sessionSynchronizer: SessionSynchronizer
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
            guard let stream = session.allStreams.first(where: { ($0.sensorName!.contains(option.title)) }) else { return }
            guard stream.sensorName != nil else { return }
            arrayOfContent.append(stream.sensorName!)
        }
        return arrayOfContent
    }
    
    init(session: SessionEntity) {
        self.session = session
        
        var sessionStreams: [MeasurementStreamEntity] {
            return session.sortedStreams.filter( {!$0.gotDeleted} ) 
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
                    streamName = streamName
                        .replacingOccurrences(of: "-", with: ":")
                        .components(separatedBy: ":")[1]
                    streamOptions.append(.init(id: id, title: streamName, isSelected: false, isEnabled: false))
                }
            }
        }
    }
    
    func deleteSelected() {
        deletingStorage.accessStorage { [self] storage in
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
           executeSyncAfterRemove()
        }
    }
    
    private func executeSyncAfterRemove() {
        guard sessionSynchronizer.syncInProgress.value else {
            sessionSynchronizer.triggerSynchronization(options: [.upload, .remove])
            return
        }
        var subscription: AnyCancellable?
        subscription = sessionSynchronizer.syncInProgress.receive(on: DispatchQueue.main).sink { value in
            guard value == false else { return }
            self.sessionSynchronizer.triggerSynchronization(options: [.upload, .remove])
            subscription?.cancel()
        }
        return
    }
    
    private func processStreamDeleting() {
        self.deletingStorage.accessStorage { [self] storage in
            guard let sessionToPass = try? storage.getExistingSession(with: session.uuid) else { return }
            streamRemover.updateSession(session: sessionToPass) { [self] result in
                switch result {
                case .success(let updateData):
                    self.deletingStorage.accessStorage { storage in
                        try? storage.deleteStreams(self.session.uuid)
                        try? storage.updateVersion(for: sessionToPass.uuid, to: updateData.version)
                    }
                case .failure(let error):
                    Log.info("Failed updating session while deleting streams: \(error.localizedDescription)")
                    self.deletingStorage.accessStorage { storage in
                        try? storage.deleteStreams(self.session.uuid)
                    }
                }
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
