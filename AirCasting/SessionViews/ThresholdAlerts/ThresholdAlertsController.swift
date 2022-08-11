// Created by Lunar on 10/08/2022.
//

import Foundation
import Resolver

protocol ThresholdAlertsController {
    func getAlerts(sessionUUID: SessionUUID, completion: @escaping (Result<[FetchedThresholdAlert], Error>) -> Void)
    func processAlerts(delete toDelete: [DeleteAlertData], create toCreate: [NewThresholdAlertData], update toUpdate: [UpdateAlertData], completion: @escaping (Result<Void, ThresholdAlertsError>) -> Void)
}

enum ThresholdAlertsError: Error {
    case failedRequestsForAlerts([String])
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
    let createAlertApiCommunitator: CreateThresholdAlertAPI = DefaultCreateThresholdAlertAPI()
    let deleteAlertApiCommunitator: DeleteThresholdAlertAPI = DefaultDeleteThresholdAlertAPI()
    let fetchAlertsApiCommunitator: FetchThresholdAlertsAPI = DefaultFetchThresholdAlertsAPI()
    
    func getAlerts(sessionUUID: SessionUUID, completion: @escaping (Result<[FetchedThresholdAlert], Error>) -> Void) {
        fetchAlertsApiCommunitator.fetchAlerts { result in
            switch result {
            case .success(let existingAlerts):
                let alertsOfTheSession = existingAlerts.filter({ $0.sessionUuid == sessionUUID.rawValue })
                Log.info("## Response: \(alertsOfTheSession)")
                completion(.success(alertsOfTheSession))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func processAlerts(delete toDelete: [DeleteAlertData], create toCreate: [NewThresholdAlertData], update toUpdate: [UpdateAlertData], completion: @escaping (Result<Void, ThresholdAlertsError>) -> Void) {
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
                if case let .failedRequestsForAlerts(failedDeletingAlerts) = error {
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
                if case let .failedRequestsForAlerts(failedCreatingAlerts) = error {
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
                if case let .failedRequestsForAlerts(failedUpdatingAlerts) = error {
                    failedAlerts.append(contentsOf: failedUpdatingAlerts)
                }
            }
            mainGroup.leave()
        }
        
        mainGroup.wait()
        failedAlerts.isEmpty ? completion(.success(())) : completion(.failure(.failedRequestsForAlerts(failedAlerts)))
    }
    
    private func deleteAlerts(_ alerts: [DeleteAlertData], completion: @escaping (Result<Void, ThresholdAlertsError>) -> Void) {
        var failedAlerts: [String] = []
        let group = DispatchGroup()
        alerts.forEach {alert in
            group.enter()
            deleteAlertApiCommunitator.deleteAlert(id: alert.id) { result in
                switch result {
                case .success():
                    Log.info("## Deleted: \(alert)")
                case .failure(_):
                    Log.info("## Failed deleting")
                    failedAlerts.append(self.shorten(alert.sensorName))
                }
                group.leave()
            }
        }
        group.wait()
        Log.info("## FINISHED DELETING")
        failedAlerts.isEmpty ? completion(.success(())) : completion(.failure(.failedRequestsForAlerts(failedAlerts)))
    }
    
    private func createAlerts(alerts: [NewThresholdAlertData], completion: (Result<Void, ThresholdAlertsError>) -> Void) {
        var failedAlerts: [String] = []
        let group = DispatchGroup()
        alerts.forEach { alert in
            group.enter()
            createAlertApiCommunitator.createAlert(sessionUUID: alert.sessionUUID, sensorName: self.shorten(alert.sensorName), thresholdValue: String(alert.thresholdValue), frequency: alert.frequency) { result in
                switch result {
                case .success(let id):
                    Log.info("Created alert for: \(alert.sensorName)")
                case .failure(let error):
                    Log.error("Failed to create an alert on backend: \(error)")
                    failedAlerts.append(self.shorten(alert.sensorName))
                }
                group.leave()
            }
        }
        group.wait()
        Log.info("## FINISHED CREATING")
        failedAlerts.isEmpty ? completion(.success(())) : completion(.failure(.failedRequestsForAlerts(failedAlerts)))
    }
    
    private func updateAlerts(alerts: [UpdateAlertData], completion: @escaping (Result<Void, ThresholdAlertsError>) -> Void) {
        var failedAlerts: [String] = []
        let group = DispatchGroup()
        alerts.forEach {alert in
            group.enter()
            deleteAlertApiCommunitator.deleteAlert(id: alert.oldId) { result in
                switch result {
                case .success():
                    Log.info("## Deleted from backed: \(alert.oldId)")
                    self.createAlertApiCommunitator.createAlert(sessionUUID: alert.sessionUUID, sensorName: self.shorten(alert.sensorName), thresholdValue: String(alert.newThresholdValue), frequency: alert.newFrequency) { result in
                        switch result {
                        case .success(let id):
                            Log.info("Updated alert for: \(alert.sensorName)")
                        case .failure(let error):
                            Log.error("Failed to create an alert on backend: \(error)")
                            failedAlerts.append(self.shorten(alert.sensorName))
                        }
                        group.leave()
                    }
                case .failure(_):
                    Log.info("## Failed deleting")
                    failedAlerts.append(self.shorten(alert.sensorName))
                    group.leave()
                }
            }
        }
        group.wait()
        Log.info("## FINISHED UPDATING")
        failedAlerts.isEmpty ? completion(.success(())) : completion(.failure(.failedRequestsForAlerts(failedAlerts)))
    }
    
    private func shorten(_ streamName: String) -> String {
        String(streamName.replacingOccurrences(of: ":", with: "-").split(separator: "-").last ?? "")
    }
}
