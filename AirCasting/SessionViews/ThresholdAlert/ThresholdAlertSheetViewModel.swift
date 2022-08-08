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
    
    struct AlertOption: Identifiable {
        var id: Int
        var sensorName: String
        var shortSensorName: String
        var isOn: Bool
        var thresholdValue: String
        var frequency: ThresholdAlertFrequency
        var valid: Bool = true
        
        static func ==(lhs: AlertOption, rhs: Alert) -> Bool {
            lhs.thresholdValue == rhs.thresholdValue && lhs.frequency == lhs.frequency && lhs.isOn
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
        let streamsWithEmptyThresholds = streamOptions.filter({ $0.isOn && $0.thresholdValue == "" }).map(\.id)
        
        guard streamsWithEmptyThresholds.isEmpty else {
            streamsWithEmptyThresholds.forEach({ streamOptions[$0].valid = false })
            return
        }
        
        var toDelete: [Int] = []
        var toCreate: [AlertOption] = []
        
        streamOptions.forEach { alertOption in
            if let activeAlert = activeAlerts.get?.first(where: { $0.sensorName == alertOption.sensorName }) {
                if alertOption == activeAlert {
                    Log.info("\(alertOption) is equal \(activeAlert)")
                    return
                } else {
                    if alertOption.isOn {
                        toDelete.append(activeAlert.id)
                        toCreate.append(alertOption)
                    } else {
                        toDelete.append(activeAlert.id)
                    }
                }
            } else {
                alertOption.isOn ? toCreate.append(alertOption) : nil
            }
            
            deleteAlerts(ids: toDelete)
            createAlerts(alerts: toCreate)
        }
    }
    
    func deleteAlerts(ids: [Int]) {
        alertsStore.deleteAlerts(ids: ids) {_ in }
    }
    
    func createAlerts(alerts: [AlertOption]) {
        alerts.forEach { alert in
            alertsStore.createAlert(id: alert.id, sessionUUID: session.uuid.rawValue, sensorName: alert.sensorName, thresholdValue: Double(alert.thresholdValue) ?? 0.0, frequency: alert.frequency.rawValue()) { _ in }
        }
    }
    
    func updateAlert() {
        
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
    
    func shorten(_ streamName: String) -> String {
        String(streamName.replacingOccurrences(of: ":", with: "-").split(separator: "-").last ?? "")
    }
}
