// Created by Lunar on 10/08/2022.
//

import Foundation
import Resolver

protocol ThresholdAlertsController {
    func getAlerts(sessionUUID: SessionUUID, completion: @escaping (Result<[FetchedThresholdAlert], Error>) -> Void)
    func processAlerts(delete toDelete: [DeleteAlertData], create toCreate: [NewThresholdAlertData], update toUpdate: [UpdateAlertData], completion: @escaping (Result<Void, ThresholdAlertsError>) -> Void)
}

enum ThresholdAlertsError: Error {
    case failedRequests
}

struct DeleteAlertData {
    let id: Int
    let sensorName: String
}

struct UpdateAlertData {
    let sensorName: String
    let sessionUUID: SessionUUID
    let oldId: Int
    let newThresholdValue: Double
    let newFrequency: ThresholdAlertFrequency
}

struct NewThresholdAlertData {
    let sensorName: String
    let sessionUUID: SessionUUID
    let thresholdValue: Double
    let frequency: ThresholdAlertFrequency
}

class DefaultThresholdAlertsController: ThresholdAlertsController {
    private let createAlertApiCommunitator: CreateThresholdAlertService = DefaultCreateThresholdAlertAPI()
    private let deleteAlertApiCommunitator: DeleteThresholdAlertService = DefaultDeleteThresholdAlertAPI()
    private let fetchAlertsApiCommunitator: FetchThresholdAlertsService = DefaultFetchThresholdAlertsAPI()
    
    func getAlerts(sessionUUID: SessionUUID, completion: @escaping (Result<[FetchedThresholdAlert], Error>) -> Void) {
        fetchAlertsApiCommunitator.fetchAlerts { result in
            switch result {
            case .success(let existingAlerts):
                let alertsOfTheSession = existingAlerts.filter({ $0.sessionUuid == sessionUUID.rawValue })
                completion(.success(alertsOfTheSession))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func processAlerts(delete toDelete: [DeleteAlertData], create toCreate: [NewThresholdAlertData], update toUpdate: [UpdateAlertData], completion: @escaping (Result<Void, ThresholdAlertsError>) -> Void) {
        var failed = false
        let mainGroup = DispatchGroup()
        
            mainGroup.enter() // creating
            mainGroup.enter() // deleting
            mainGroup.enter() // updating
            
            self.deleteAlerts(toDelete) { result in
                switch result {
                case .success():
                    Log.info("Deleted alerts successfully")
                case .failure(let error):
                    Log.error("Deleting request failed: \(error)")
                    failed = true
                }
                mainGroup.leave()
            }
            
            self.createAlerts(alerts: toCreate) { result in
                switch result {
                case .success():
                    Log.info("Created alerts successfully")
                case .failure(let error):
                    Log.error("Creating request failed: \(error)")
                    failed = true
                }
                mainGroup.leave()
            }
            
            self.updateAlerts(alerts: toUpdate) { result in
                switch result {
                case .success():
                    Log.info("Updated alerts successfully")
                case .failure(let error):
                    Log.error("Updating request failed: \(error)")
                    failed = true
                }
                mainGroup.leave()
            }
        
        mainGroup.notify(queue: DispatchQueue.main) {
            !failed ? completion(.success(())) : completion(.failure(.failedRequests))
        }
    }
    
    private func deleteAlerts(_ alerts: [DeleteAlertData], completion: @escaping (Result<Void, ThresholdAlertsError>) -> Void) {
        var failed = false
        let group = DispatchGroup()
        alerts.forEach {alert in
            group.enter()
            deleteAlertApiCommunitator.deleteAlert(id: alert.id) { result in
                if case .failure(_) = result {
                    failed = true
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.global()) {
            failed ? completion(.failure(.failedRequests)) : completion(.success(()))
        }
    }
    
    private func createAlerts(alerts: [NewThresholdAlertData], completion: @escaping (Result<Void, ThresholdAlertsError>) -> Void) {
        var failed = false
        let group = DispatchGroup()
        alerts.forEach { alert in
            group.enter()
            createAlertApiCommunitator.createAlert(sessionUUID: alert.sessionUUID, sensorName: alert.sensorName, thresholdValue: String(alert.thresholdValue), frequency: alert.frequency) { result in
                switch result {
                case .success(_):
                    Log.info("Created alert for: \(alert.sensorName)")
                case .failure(let error):
                    Log.error("Failed to create an alert on backend: \(error)")
                    failed = true
                }
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.global()) {
            !failed ? completion(.success(())) : completion(.failure(.failedRequests))
        }
    }
    
    private func updateAlerts(alerts: [UpdateAlertData], completion: @escaping (Result<Void, ThresholdAlertsError>) -> Void) {
        var failed = false
        let group = DispatchGroup()
        alerts.forEach {alert in
            group.enter()
            deleteAlertApiCommunitator.deleteAlert(id: alert.oldId) { result in
                switch result {
                case .success():
                    Log.info("Deleted from backed: \(alert.oldId)")
                    self.createAlertApiCommunitator.createAlert(sessionUUID: alert.sessionUUID, sensorName: alert.sensorName, thresholdValue: String(alert.newThresholdValue), frequency: alert.newFrequency) { result in
                        switch result {
                        case .success(_):
                            Log.info("Updated alert for: \(alert.sensorName)")
                        case .failure(let error):
                            Log.error("Failed to create an alert on backend: \(error)")
                            failed = true
                        }
                        group.leave()
                    }
                case .failure(let error):
                    Log.error("Failed to delete an alert on backend: \(error)")
                    failed = true
                    group.leave()
                }
            }
        }
        group.notify(queue: DispatchQueue.global()) {
            !failed ? completion(.success(())) : completion(.failure(.failedRequests))
        }
    }
}
