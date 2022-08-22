class DefaultFeatureFlagProvider: FeatureFlagProvider {
    var onFeatureListChange: (() -> Void)?
    
    func isFeatureOn(_ feature: FeatureFlag) -> Bool? {
        switch feature {
        case .sdCardSync:
            #if DEBUG
            return true
            #else
            return true
            #endif
        case .standaloneMode:
            #if DEBUG
            return true
            #else
            return true
            #endif
        case .notes:
            #if DEBUG
            return true
            #else
            return true
            #endif
        case .locationlessSessions:
            #if DEBUG
            return true
            #else
            return true
            #endif
        case .searchAndFollow:
            #if DEBUG
            return true
            #else
            return true
            #endif
        case .deleteAccount:
            #if DEBUG
            return true
            #else
            return true
            #endif
        }
    }
}
