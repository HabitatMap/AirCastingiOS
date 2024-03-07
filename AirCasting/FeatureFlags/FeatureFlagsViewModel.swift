import Foundation
import Resolver

class FeatureFlagsViewModel: ObservableObject {
    @Published var enabledFeatures: [FeatureFlag] = []
    
    @Injected private var provider: FeatureFlagProvider
    #if DEBUG || BETA
    @Injected private var overrides: OverridingFeatureFlagProvider
    #endif
    
    #if DEBUG || BETA
    func overrideFeature(_ feature: FeatureFlag, with value: Bool) {
        overrides.overrides[feature] = value
    }
    #endif
    
    init() {
        self.provider.onFeatureListChange = { [weak self] in self?.updateList() }
        updateList()
    }
    
    private func updateList() {
        enabledFeatures = FeatureFlag.allCases.filter { provider.isFeatureOn($0) ?? false }
        Log.info("Updated feature list: \(self.enabledFeatures)")
    }
}
