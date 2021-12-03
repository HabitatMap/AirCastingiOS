// Created by Lunar on 03/12/2021.
//

import Foundation

class OverridingFeatureFlagProvider: FeatureFlagProvider, ObservableObject {
    private let userDefaultsKey = "feature.flag.overrides"
    
    var onFeatureListChange: (() -> Void)?
    
    var overrides: [FeatureFlag: Bool] = [:] {
        didSet {
            objectWillChange.send()
            onFeatureListChange?()
            UserDefaults.standard.set(toJsonDict(), forKey: userDefaultsKey)
        }
    }
    
    init() {
        guard let saved = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: Bool] else { return }
        overrides = fromJsonDict(json: saved)
    }
    
    private func toJsonDict() -> [String: Bool] {
        overrides.map { ($0.0.rawValue, $0.1) }.reduce(into: [:], { $0[$1.0] = $1.1 })
    }
    
    private func fromJsonDict(json: [String: Bool]) -> [FeatureFlag: Bool] {
        json.compactMap { keyValuePair -> (FeatureFlag, Bool)? in
            guard let flag = FeatureFlag(rawValue: keyValuePair.0) else { return nil }
            return (flag, keyValuePair.1)
        }.reduce(into: [:], { $0[$1.0] = $1.1 })
    }
    
    func isFeatureOn(_ feature: FeatureFlag) -> Bool? {
        overrides[feature]
    }
}
