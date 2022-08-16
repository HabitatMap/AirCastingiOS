class DefaultFeatureFlagProvider: FeatureFlagProvider {
    var onFeatureListChange: (() -> Void)?
    
    func isFeatureOn(_ feature: FeatureFlag) -> Bool? {
        switch feature {
        case .sdCardSync:
            #if DEBUG
            return true
            #else
            return false
            #endif
        case .standaloneMode:
            #if DEBUG
            return true
            #else
            return false
            #endif
        case .notes:
            #if DEBUG
            return true
            #else
            return false
            #endif
        case .locationlessSessions:
            #if DEBUG
            return true
            #else
            return false
            #endif
        case .searchAndFollow:
            #if DEBUG
            return true
            #else
            return false
            #endif
        case .deleteAccount:
            #if DEBUG
            return true
            #else
            return false
            #endif
        case .microphoneCalibration:
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
        
    }
}
