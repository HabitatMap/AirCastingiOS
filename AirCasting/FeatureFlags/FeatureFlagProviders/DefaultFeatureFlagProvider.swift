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
        case .disableMapping:
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
        
    }
}
