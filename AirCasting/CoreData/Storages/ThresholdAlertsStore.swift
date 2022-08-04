// Created by Lunar on 04/08/2022.
//

import Foundation
import CoreData

protocol ThresholdAlertsStore {
    func getAlertsForSession(uuid: String, completion: @escaping (Result<[ThresholdAlert], Error>) -> Void)
    func deleteAlerts(ids: [Int], completion: @escaping (Result<Void, Error>) -> Void)
    func createAlert(id: Int, sessionUUID: String, sensorName: String, thresholdValue: Double, frequency: Int, completion: @escaping (Result<Void, Error>) -> Void)
}

class DefaultThresholdAlertsStore: ThresholdAlertsStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getAlertsForSession(uuid: String, completion: @escaping (Result<[ThresholdAlert], Error>) -> Void) {
        let fetchRequest = ThresholdAlert.fetchRequest()
        let predicate = NSPredicate(format: "sessionUUID = %@", uuid)
        fetchRequest.predicate = predicate
        
        context.perform {
            do {
                let result = try self.context.fetch(fetchRequest)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func deleteAlerts(ids: [Int], completion: @escaping (Result<Void, Error>) -> Void) {
        let fetchRequest = ThresholdAlert.fetchRequest()
        let predicate = NSPredicate(format: "id IN %@", ids)
        fetchRequest.predicate = predicate
        
        context.perform {
            do {
                let result = try self.context.fetch(fetchRequest)
                result.forEach({ self.context.delete($0) })
                try self.context.save()
                Log.debug("## deleted alerts: \(result)")
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func createAlert(id: Int, sessionUUID: String, sensorName: String, thresholdValue: Double, frequency: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        enum CreatingThresholdAlertError: Error {
            case sessionAlreadyExists
        }

        context.perform {
            do {
                let alert = ThresholdAlert(context: self.context)
                alert.id = Int16(id)
                alert.sensorName = sensorName
                alert.sessionUUID = UUID(uuidString: sessionUUID)
                alert.thresholdValue = thresholdValue
                alert.frequency = Int16(frequency)
                
                try self.context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
