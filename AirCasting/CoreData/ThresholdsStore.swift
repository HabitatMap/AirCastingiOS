// Created by Lunar on 31/03/2022.
//

import CoreData

protocol ThresholdsStore {
    func getThresholdsValues(for sensorName: String, completion: @escaping (Result<ThresholdsValue, Error>) -> Void)
}

struct DefaultThresholdsStore: ThresholdsStore {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getThresholdsValues(for sensorName: String, completion: @escaping (Result<ThresholdsValue, Error>) -> Void) {
        let request = SensorThreshold.fetchRequest()
        request.predicate = NSPredicate(format: "sensorName CONTAINS[cd] %@", sensorName)
        context.perform {
            do {
                let result = try context.fetch(request)
                
                guard let thresholds = result.first else {
                    Log.warning("Didn't find thresholds for \(sensorName)")
                    completion(.success(ThresholdsValue(veryLow: .max, low: .max, medium: .max, high: .max, veryHigh: .max)))
                    return
                }
                
                if result.count > 1 {
                    let names = result.compactMap(\.sensorName).joined(separator: ",")
                    Log.error("More than one threshold found for \(sensorName): \(names)")
                }
                
                completion(.success(ThresholdsValue(veryLow: thresholds.thresholdVeryLow, low: thresholds.thresholdLow, medium: thresholds.thresholdMedium, high: thresholds.thresholdHigh, veryHigh: thresholds.thresholdVeryHigh)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
