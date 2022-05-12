// Created by Lunar on 16/12/2021.
//

import Foundation

enum ShareSessionError: Error {
    case noSessionURL
    case requestError
}

enum ShareSessionResult {
    case linkShared
    case fileShared
    case cancelled
}

protocol ShareSessionViewModel: ObservableObject {
    var streamOptions: [ShareSessionStreamOptionViewModel] { get set }
    var alert: AlertInfo? { get set }
    var showShareSheet: Bool { get set }
    var showInvalidEmailError: Bool { get set }
    var sharingLink: URL? { get set }
    var email: String { get set }
    func didSelect(option: ShareSessionStreamOptionViewModel)
    func shareLinkTapped()
    func shareEmailTapped()
    func cancelTapped()
    func sharingFinished()
    func getSharePage() -> ActivityViewController?
}

class DefaultShareSessionViewModel: ShareSessionViewModel {
    @Published var alert: AlertInfo?
    @Published var showShareSheet: Bool = false
    @Published var showInvalidEmailError: Bool = false
    @Published var sharingLink: URL?
    @Published var email: String = ""
    private let exitRoute: (ShareSessionResult) -> Void
    private var session: SessionEntity
    private lazy var selectedStream = streamOptions.first
    private let apiClient: ShareSessionAPIServices
    
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
    
    func shareLinkTapped() {
        getSharingLink()
        guard sharingLink != nil else {
            getAlert(.noSessionURL)
            return
        }
        showShareSheet = true
    }
    
    func cancelTapped() {
        exitRoute(.cancelled)
    }
    
    func sharingFinished() {
        showShareSheet = false // this is kind of redundant, but also necessary for the shareSessionModal to disappear
        exitRoute(.linkShared)
    }
    
    private func isEmailValid() -> Bool {
        // regex taken from https://regexlib.com/Search.aspx?k=email&c=-1&m=5&ps=20
        let emailTest = NSPredicate(format: "SELF MATCHES %@", #"^((([!#$%&'*+\-/=?^_`{|}~\w])|([!#$%&'*+\-/=?^_`{|}~\w][!#$%&'*+\-/=?^_`{|}~\.\w]{0,}[!#$%&'*+\-/=?^_`{|}~\w]))[@]\w+([-.]\w+)*\.\w+([-.]\w+)*)$"#)
        return emailTest.evaluate(with: email)
    }
    
    func shareEmailTapped() {
        if isEmailValid() {
            showInvalidEmailError = false
            sendRequest()
        } else {
            showInvalidEmailError = true
        }
    }
    
    func getSharePage() -> ActivityViewController? {
        guard sharingLink != nil else { return nil }
        return ActivityViewController(sharingFile: false, itemToShare: sharingLink!) { activityType, completed, returnedItems, error in
            self.sharingFinished()
        }
    }
    
    private func sendRequest() {
        apiClient.sendSession(email: email, uuid: session.uuid.rawValue) { result in
            switch result {
            case .success():
                self.exitRoute(.fileShared)
            case .failure(let error):
                Log.info("Share session request error: \(error)")
                self.getAlert(.requestError)
            }
        }
    }
    
    private func getSharingLink() {
        guard let sessionURL = session.urlLocation,
              var components = URLComponents(string: sessionURL)
        else {
            Log.error("No URL for session \(String(describing: session.uuid))")
            return
        }
        
        components.queryItems = [URLQueryItem(name: "sensor_name", value: selectedStream?.streamName)]
        
        guard let url = components.url else {
            Log.error("Coudn't compose url for session \(String(describing: session.uuid))")
            return
        }
        
        sharingLink = url
    }
    
    private func getAlert(_ error: ShareSessionError) {
        DispatchQueue.main.async {
            switch error {
            case .noSessionURL:
                self.alert = InAppAlerts.failedSharingAlert()
            case .requestError:
                self.alert = InAppAlerts.failedSharingAlert()
            }
        }
    }
    
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

class DummyShareSessionViewModel: ShareSessionViewModel {
    func getSharePage() -> ActivityViewController? { return nil }
    var showInvalidEmailError: Bool = false
    var email: String = "a@test.com"
    func isEmailValid() -> Bool { false }
    var streamOptions: [ShareSessionStreamOptionViewModel] = []
    var alert: AlertInfo?
    var showShareSheet: Bool = false
    var sharingLink: URL?
    func didSelect(option: ShareSessionStreamOptionViewModel) { }
    func shareLinkTapped() { }
    func shareEmailTapped() { }
    func cancelTapped() { }
    func sharingFinished() { }
}
