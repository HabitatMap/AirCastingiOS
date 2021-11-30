import Foundation

enum FeatureFlag: Equatable, CaseIterable {
    case sdCardSync
    case standaloneMode
}

extension FeatureFlag {
    var name: String {
        switch self {
        case .standaloneMode: return "Standalone mode"
        case .sdCardSync: return "SD Card sync"
        }
    }
}

protocol FeatureFlagProvider {
    /// This will get called anytime the feature list is changed
    var onFeatureListChange: (() -> Void)? { get set }
    /// Function used to determine if a feature at hand is turned on or off
    /// - Returns: `Bool` value indicating wheter the feature is turned on or off. Nil means undetermined and is used mainly by remote providers when they cannot fetch configuration.
    func isFeatureOn(_ feature: FeatureFlag) -> Bool?
}
