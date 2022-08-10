class DefaultFeatureFlagProvider: FeatureFlagProvider {
    var onFeatureListChange: (() -> Void)?
    
    func isFeatureOn(_ feature: FeatureFlag) -> Bool? {
        switch feature {
        default:
            return true
        }
    }
}
