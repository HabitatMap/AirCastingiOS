// Created by Lunar on 01/08/2022.
//

import Foundation
import Resolver

enum ThresholdAlertFrequency {
    case oneHour
    case twentyFourHours
    
    init(_ value: Int) {
        switch value {
        case 24:
            self = .twentyFourHours
        default:
            self = .oneHour
        }
    }
    
    func rawValue() -> Int {
        switch self {
        case .oneHour:
            return 1
        case .twentyFourHours:
            return 24
        }
    }
}

class ThresholdAlertSheetViewModel: ObservableObject {
    @Published var isOn = false
    private var session: Sessionable
    private let apiClient: ShareSessionAPIServices
    @Injected var alertsStore: ThresholdAlertsStore
    
    @Published var streamOptions: [AlertOption] = []
    @Published var frequency = ThresholdAlertFrequency.oneHour
    @Published var activeAlerts: Loadable<[Alert]> = .loading {
        didSet {
            saveButtonEnabled = true
        }
    }
    @Published var saveButtonEnabled = false
    
    let createAlertApiCommunitator: CreateThresholdAlertAPI = DefaultCreateThresholdAlertAPI()
    let deleteAlertApiCommunitator: DeleteThresholdAlertAPI = DefaultDeleteThresholdAlertAPI()
    
    struct AlertOption: Identifiable {
        var id: Int
        var sensorName: String
        var shortSensorName: String
        var isOn: Bool
        var thresholdValue: String
        var frequency: ThresholdAlertFrequency
        var valid: Bool = true
        
        static func ==(lhs: AlertOption, rhs: Alert) -> Bool {
            lhs.thresholdValue == rhs.thresholdValue && lhs.frequency == rhs.frequency && lhs.isOn
        }
    }
    
    struct Alert {
        var id: Int
        var sensorName: String
        var thresholdValue: String
        var frequency: ThresholdAlertFrequency
    }
    
    init(session: Sessionable, apiClient: ShareSessionAPIServices) {
        self.session = session
        self.apiClient = apiClient
        Log.info("## INIT")
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
    
    func changeFrequency(of id: Int, to value: ThresholdAlertFrequency) {
        guard let streamOptionId = streamOptions.first(where: { $0.id == id })?.id else { return }
        streamOptions[streamOptionId].frequency = value
        Log.info("## \(streamOptions[streamOptionId])")
    }
    
    func save(completion: () -> Void) {
        Log.info("## saving")
        let streamsWithEmptyThresholds = streamOptions.filter({ $0.isOn && ($0.thresholdValue == "" || Double($0.thresholdValue) == nil) }).map(\.id)
        
        guard streamsWithEmptyThresholds.isEmpty else {
            streamsWithEmptyThresholds.forEach({ streamOptions[$0].valid = false })
            return
        }
        
        var toDelete: [Alert] = []
        var toCreate: [AlertOption] = []
        var toUpdate: [(oldAlert: Alert, newAlert: AlertOption)] = []
        
        Log.info("## alert options: \(streamOptions)")
        streamOptions.forEach { alertOption in
            if let activeAlert = activeAlerts.get?.first(where: { $0.sensorName == alertOption.sensorName }) {
                if alertOption == activeAlert {
                    Log.info("\(alertOption) is equal \(activeAlert)")
                    return
                } else {
                    if alertOption.isOn {
                        toUpdate.append((oldAlert: activeAlert, newAlert: alertOption))
                    } else {
                        toDelete.append(activeAlert)
                    }
                }
            } else {
                alertOption.isOn ? toCreate.append(alertOption) : nil
            }
        }
        
        var failedAlerts: [String] = []
        let mainGroup = DispatchGroup()
        
        mainGroup.enter() // creating
        mainGroup.enter() // deleting
        mainGroup.enter() // updating
        
        deleteAlerts(toDelete) { result in
            switch result {
            case .success():
                Log.info("Deleted alerts successfully")
            case .failure(let error):
                if case let .failedDeleting(failedDeletingAlerts) = error {
                    failedAlerts.append(contentsOf: failedDeletingAlerts)
                }
            }
            mainGroup.leave()
        }
        
        createAlerts(alerts: toCreate) { result in
            switch result {
            case .success():
                Log.info("Created alerts successfully")
            case .failure(let error):
                if case let .failedCreating(failedCreatingAlerts) = error {
                    failedAlerts.append(contentsOf: failedCreatingAlerts)
                }
            }
            mainGroup.leave()
        }
        
        updateAlerts(alerts: toUpdate) { result in
            switch result {
            case .success():
                Log.info("Updated alerts successfully")
            case .failure(let error):
                if case let .failedCreating(failedCreatingAlerts) = error {
                    failedAlerts.append(contentsOf: failedCreatingAlerts)
                }
            }
            mainGroup.leave()
        }
        
        mainGroup.wait()
        Log.info("## Failed alerts: \(failedAlerts)")
    }
    
    enum AlertAPIError: Error {
        case failedCreating([String])
        case failedDeleting([String])
    }
    
    private func deleteAlerts(_ alerts: [Alert], completion: @escaping (Result<Void, AlertAPIError>) -> Void) {
        var failedAlerts: [String] = []
        let group = DispatchGroup()
        alerts.forEach {alert in
            group.enter()
            deleteAlertApiCommunitator.DeleteAlert(id: alert.id) { result in
                switch result {
                case .success():
                    Log.info("## Deleted: \(alert)")
                    self.alertsStore.deleteAlerts(ids: [alert.id]) {_ in }
                case .failure(_):
                    Log.info("## Failed deleting")
                    failedAlerts.append(self.shorten(alert.sensorName))
                }
                group.leave()
            }
        }
        group.wait()
        Log.info("## FINISHED DELETING")
        failedAlerts.isEmpty ? completion(.success(())) : completion(.failure(.failedDeleting(failedAlerts)))
    }
    
    private func createAlerts(alerts: [AlertOption], completion: (Result<Void, AlertAPIError>) -> Void) {
        var failedAlerts: [String] = []
        let group = DispatchGroup()
        alerts.forEach { alert in
            group.enter()
            createAlertApiCommunitator.createAlert(sessionUUID: session.uuid, sensorName: alert.shortSensorName, thresholdValue: alert.thresholdValue, frequency: alert.frequency) { result in
                switch result {
                case .success(let id):
                    self.alertsStore.createAlert(id: id.id, sessionUUID: self.session.uuid.rawValue, sensorName: alert.sensorName, thresholdValue: Double(alert.thresholdValue) ?? 0.0, frequency: alert.frequency.rawValue()) { result in
                        switch result {
                        case .success():
                            Log.info("Created alert for: \(alert.sensorName)")
                        case .failure(let error):
                            // it's not a big problem if it fails as long as we are syncing with database when entering this view
                            Log.error("Failed to create an alert in the database: \(error)")
                        }
                    }
                case .failure(let error):
                    Log.error("Failed to create an alert on backend: \(error)")
                    failedAlerts.append(alert.shortSensorName)
                }
                group.leave()
            }
        }
        group.wait()
        Log.info("## FINISHED CREATING")
        failedAlerts.isEmpty ? completion(.success(())) : completion(.failure(.failedCreating(failedAlerts)))
    }
    
    private func updateAlerts(alerts: [(oldAlert: Alert, newAlert: AlertOption)], completion: @escaping (Result<Void, AlertAPIError>) -> Void) {
        var failedAlerts: [String] = []
        let group = DispatchGroup()
        alerts.forEach {alert in
            group.enter()
            deleteAlertApiCommunitator.DeleteAlert(id: alert.oldAlert.id) { result in
                switch result {
                case .success():
                    Log.info("## Deleted from backed: \(alert.oldAlert)")
                    self.createAlertApiCommunitator.createAlert(sessionUUID: self.session.uuid, sensorName: alert.newAlert.shortSensorName, thresholdValue: alert.newAlert.thresholdValue, frequency: alert.newAlert.frequency) { result in
                        switch result {
                        case .success(let id):
                            self.alertsStore.updateAlert(oldId: alert.oldAlert.id, newId: id.id, thresholdValue: Double(alert.newAlert.thresholdValue) ?? 0.0, frequency: alert.newAlert.frequency.rawValue()) { result in
                                switch result {
                                case .success():
                                    Log.info("Updated alert for: \(alert.newAlert.sensorName)")
                                case .failure(let error):
                                    // it's not a big problem if it fails as long as we are syncing with database when entering this view
                                    Log.error("Failed to update an alert in the database: \(error)")
                                }
                            }
                        case .failure(let error):
                            Log.error("Failed to create an alert on backend: \(error)")
                            failedAlerts.append(alert.newAlert.shortSensorName)
                        }
                        group.leave()
                    }
                case .failure(_):
                    Log.info("## Failed deleting")
                    failedAlerts.append(self.shorten(alert.oldAlert.sensorName))
                    group.leave()
                }
            }
        }
        group.wait()
        failedAlerts.isEmpty ? completion(.success(())) : completion(.failure(.failedDeleting(failedAlerts)))
    }
    
    private func showProperStreams() {
        activeAlerts = .loading
        alertsStore.getAlertsForSession(uuid: session.uuid.rawValue) { result in
            switch result {
            case .success(let dbAlerts):
                let alerts: [Alert] = dbAlerts.compactMap { alert in
                    guard let sensorName = alert.sensorName else {
                        return nil
                    }
                    return Alert(id: Int(alert.id), sensorName: sensorName, thresholdValue: String(alert.thresholdValue), frequency: .init(Int(alert.frequency)))
                }
                let sessionStreams = self.session.sortedStreams.filter( {!$0.gotDeleted} )
                self.streamOptions = []
                var i = 0
                sessionStreams.forEach { stream in
                    guard let name = stream.sensorName else { return }
                    let streamAlert = alerts.first(where: { $0.sensorName == stream.sensorName })
                    self.streamOptions.append(AlertOption(id: i, sensorName: name, shortSensorName: self.shorten(name), isOn: streamAlert != nil, thresholdValue: streamAlert?.thresholdValue ?? "", frequency: streamAlert?.frequency ?? .oneHour))
                    i+=1
                }
                self.activeAlerts = .ready(alerts)
            case .failure(let error):
                Log.error(error.localizedDescription)
                // alert
            }
        }
    }
    
    private func shorten(_ streamName: String) -> String {
        String(streamName.replacingOccurrences(of: ":", with: "-").split(separator: "-").last ?? "")
    }
}
