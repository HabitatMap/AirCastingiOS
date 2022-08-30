// Created by Lunar on 15/11/2021.
//

import Foundation
import Resolver

class ThresholdSettingsViewModel: ObservableObject {
    
    @Published var thresholdVeryLow = ""
    @Published var thresholdLow = ""
    @Published var thresholdMedium = ""
    @Published var thresholdHigh = ""
    @Published var thresholdVeryHigh = ""
    let initialThresholds: ThresholdsValue
    var threshold: SensorThreshold
    private let formatter: ThresholdFormatter
    @Published var alert: AlertInfo?

    init(initialThresholds: ThresholdsValue, threshold: SensorThreshold) {
        self.initialThresholds = initialThresholds
        self.threshold = threshold
        self.formatter = Resolver.resolve(ThresholdFormatter.self, args: threshold)
    }

    func resetToDefault() -> ThresholdsValue { initialThresholds }
    
    func updateToNewThresholds(completion: @escaping ((Result<ThresholdsValue, Error>) -> Void)) {
        enum ThresholdValuesError: Error {
            case veryLowEqualsVeryHigh
        }
        
        guard thresholdVeryLow != thresholdVeryHigh else {
            DispatchQueue.main.async {
                self.alert = InAppAlerts.thresholdsValuesSettingsWarning()
                completion(.failure(ThresholdValuesError.veryLowEqualsVeryHigh))
            }
            return
        }
        
        var newValues: [Int32] = [thresholdVeryHigh, thresholdHigh, thresholdMedium, thresholdLow, thresholdVeryLow]
            .map { formatter.value(from: $0) ?? 0 }
            .sorted { $0 < $1 }
        
        // Prevents us from the situation when the user could change thresholds to have the same values
        newValues = newValues.reversed().mapWithNext { lowerThreshold, higherThreshold in
            guard lowerThreshold != higherThreshold else { return lowerThreshold - 1 }
            return lowerThreshold
        }.sorted { $0 < $1 }
        
        return completion(.success(ThresholdsValue(veryLow: newValues[0],
                                                   low: newValues[1],
                                                   medium: newValues[2],
                                                   high: newValues[3],
                                                   veryHigh: newValues[4])))
    }
}
