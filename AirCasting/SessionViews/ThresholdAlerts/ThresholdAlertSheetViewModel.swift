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
    private var session: Sessionable
    @Injected var controller: ThresholdAlertsController
    @Injected var networkChecker: NetworkChecker
    
    @Published var streamOptions: [AlertOption] = []
    private var activeAlerts: Loadable<[Alert]> = .loading {
        didSet {
            activeAlerts.isReady ? loading = false : nil
        }
    }
    @Published var loading = true
    @Published var isSaving = false
    @Published var saveButtonText = Strings.ThresholdAlertSheet.saveButton
    @Published var shouldDismiss = false
    @Published var alert: AlertInfo?
    
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
    
    init(session: Sessionable) {
        self.session = session
        showProperStreams()
    }
    
    func confirmationButtonPressed() {}
    
    func changeIsOn(of id: Int, to value: Bool) {
        guard let streamOptionId = streamOptions.first(where: { $0.id == id })?.id else { return }
        streamOptions[streamOptionId].isOn = value
    }
    
    func changeThreshold(of id: Int, to value: String) {
        guard let streamOptionId = streamOptions.first(where: { $0.id == id })?.id else { return }
        streamOptions[streamOptionId].thresholdValue = value
    }
    
    func changeFrequency(of id: Int, to value: ThresholdAlertFrequency) {
        guard let streamOptionId = streamOptions.first(where: { $0.id == id })?.id else { return }
        streamOptions[streamOptionId].frequency = value
    }
    
    func save(completion: () -> Void) {
        let streamsWithEmptyThresholds = streamOptions.filter({ $0.isOn && ($0.thresholdValue == "" || Double($0.thresholdValue) == nil) }).map(\.id)
        
        guard streamsWithEmptyThresholds.isEmpty else {
            streamsWithEmptyThresholds.forEach({ streamOptions[$0].valid = false })
            return
        }
        
        saveButtonText = Strings.ThresholdAlertSheet.savingButton
        isSaving = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.processChanges()
        }
    }
    
    private func processChanges() {
        var toDelete: [DeleteAlertData] = []
        var toCreate: [NewThresholdAlertData] = []
        var toUpdate: [UpdateAlertData] = []
        
        streamOptions.forEach { alertOption in
            if let activeAlert = activeAlerts.get?.first(where: { $0.sensorName == self.shorten(alertOption.sensorName) }) {
                if alertOption == activeAlert {
                    return
                } else {
                    if alertOption.isOn {
                        toUpdate.append(.init(sensorName: alertOption.sensorName, sessionUUID: self.session.uuid, oldId: activeAlert.id, newThresholdValue: Double(alertOption.thresholdValue)!, newFrequency: alertOption.frequency))
                    } else {
                        toDelete.append(.init(id: activeAlert.id, sensorName: activeAlert.sensorName))
                    }
                }
            } else {
                alertOption.isOn ? toCreate.append(.init(sensorName: alertOption.sensorName, sessionUUID: self.session.uuid, thresholdValue: Double(alertOption.thresholdValue)!, frequency: alertOption.frequency)) : nil
            }
        }
        
        controller.processAlerts(delete: toDelete, create: toCreate, update: toUpdate) { result in
            switch result {
            case .success():
                Log.info("Processed alerts successfully")
                DispatchQueue.main.async {
                    self.shouldDismiss = true
                }
            case .failure(let error):
                if case let .failedRequestsForAlerts(failedAlerts) = error {
                    Log.error("Failed alerts: \(failedAlerts)")
                }
                DispatchQueue.main.async {
                    self.alert = InAppAlerts.failedThresholdAlertsAlert {
                        self.shouldDismiss = true
                    }
                }
            }
        }
    }
    
    
    private func showProperStreams() {
        guard networkChecker.connectionAvailable else {
            alert = InAppAlerts.noInternetConnection {
                self.shouldDismiss = true
            }
            return
        }
        activeAlerts = .loading
        controller.getAlerts(sessionUUID: self.session.uuid) {result in
            switch result {
            case .success(let existingAlerts):
                let alerts: [Alert] = existingAlerts.compactMap { alert in
                    return Alert(id: Int(alert.id), sensorName: alert.sensorName, thresholdValue: String(alert.thresholdValue), frequency: .init(Int(alert.frequency)))
                }
                let sessionStreams = self.session.sortedStreams.filter( {!$0.gotDeleted} )
                var newAlertOptions: [AlertOption] = []
                var i = 0
                sessionStreams.forEach { stream in
                    guard let sensorName = stream.sensorName else { return }
                    let streamAlert = alerts.first(where: { $0.sensorName == self.shorten(sensorName) })
                    newAlertOptions.append(AlertOption(id: i, sensorName: sensorName, shortSensorName: self.shorten(sensorName), isOn: streamAlert != nil, thresholdValue: streamAlert?.thresholdValue ?? "", frequency: streamAlert?.frequency ?? .oneHour))
                    i+=1
                }
                
                DispatchQueue.main.async {
                    self.streamOptions = newAlertOptions
                    self.activeAlerts = .ready(alerts)
                }
            case .failure(let error):
                Log.error(error.localizedDescription)
                DispatchQueue.main.async {
                    self.alert = InAppAlerts.failedThresholdAlertsFetchingAlert {
                        DispatchQueue.main.async {
                            self.shouldDismiss = true
                        }
                    }
                }
            }
        }
    }
    
    private func shorten(_ streamName: String) -> String {
        String(streamName.replacingOccurrences(of: ":", with: "-").split(separator: "-").last ?? "")
    }
}
