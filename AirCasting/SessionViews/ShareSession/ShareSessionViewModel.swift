// Created by Lunar on 16/12/2021.
//

import Foundation

protocol ShareSessionViewModel: ObservableObject {
    var streamOptions: [ShareSessionStreamOptionViewModel] {get set}
    var alert: AlertInfo? { get set }
    var showSheet: Bool { get set }
    var sharingLink: URL? { get set }
    func didSelect(option: ShareSessionStreamOptionViewModel)
    func shareLinkButtonGotPressed()
}

enum ShareSessionError: Error {
    case noSessionURL
}

class DefaultShareSessionViewModel: ShareSessionViewModel {
    private var session: SessionEntity
    private lazy var selectedStream = streamOptions.first
//    @Published var showAlert: Bool = false
    @Published var alert: AlertInfo?
    @Published var showSheet: Bool = false
    @Published var sharingLink: URL?
    
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
    
    func shareLinkButtonGotPressed() {
        getSharingLink()
        showSheet = true
    }
    
    private func getSharingLink() {
        guard let sessionURL = session.urlLocation,
              var components = URLComponents(string: sessionURL)
        else {
            getAlert(.noSessionURL)
            return
        }

        components.queryItems = [URLQueryItem(name: "sensor_name", value: selectedStream?.streamName)]
        
        guard let url = components.url else {
            Log.error("Coudn't compose url for this stream")
            getAlert(.noSessionURL)
            return
        }
        
        sharingLink = url
    }
    
    private func showAlert(_ error: ShareSessionError) {
        
    }
    
    private func getAlert(_ error: ShareSessionError) {
        switch error {
        case .noSessionURL:
            alert = InAppAlerts.failedSharingAlert()
        }
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
