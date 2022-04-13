// Created by Lunar on 31/03/2022.
//

import CoreData

protocol ThresholdsStore {
    func getThresholdsValues(for sensorName: String, completion: @escaping (Result<ThresholdsValue, ThresholdsStoreError>) -> Void)
}

enum ThresholdsStoreError: Error {
    case noThresholdsFound
    case fetchRequestFailed
}

struct DefaultThresholdsStore: ThresholdsStore {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getThresholdsValues(for sensorName: String, completion: @escaping (Result<ThresholdsValue, ThresholdsStoreError>) -> Void) {
        let request = SensorThreshold.fetchRequest()
        request.predicate = NSPredicate(format: "sensorName CONTAINS[cd] %@", sensorName)
        context.perform {
            do {
                let result = try context.fetch(request)
                
                guard let thresholds = result.first else {
                    Log.warning("Didn't find thresholds for \(sensorName)")
                    completion(.failure(ThresholdsStoreError.noThresholdsFound))
                    return
                }
                
                if result.count > 1 {
                    let names = result.compactMap(\.sensorName).joined(separator: ",")
                    Log.error("More than one threshold found for \(sensorName): \(names)")
                }
                
                completion(.success(ThresholdsValue(veryLow: thresholds.thresholdVeryLow, low: thresholds.thresholdLow, medium: thresholds.thresholdMedium, high: thresholds.thresholdHigh, veryHigh: thresholds.thresholdVeryHigh)))
            } catch {
                completion(.failure(ThresholdsStoreError.fetchRequestFailed))
            }
        }
    }
}
