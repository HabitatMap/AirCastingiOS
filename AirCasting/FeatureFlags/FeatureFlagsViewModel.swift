import Foundation

class FeatureFlagsViewModel: ObservableObject {
    @Published var enabledFeatures: [FeatureFlag] = []
    
    private var provider: FeatureFlagProvider
    static private let overrides = OverridingFeatureFlagProvider()
    
    static let shared: FeatureFlagsViewModel = {
        #if DEBUG
        return .init(
            provider: CompositeFeatureFlagProvider(children: [
                FeatureFlagsViewModel.overrides,
                AllFeaturesOn()
            ])
        )
        #else
        return .init(
            provider: CompositeFeatureFlagProvider(children: [
                FeatureFlagsViewModel.overrides,
                FirebaseFeatureFlagProvider(notificationsRouter: DefaultRemoteNotificationRouter.shared),
                DefaultFeatureFlagProvider()
            ])
        )
        #endif
    }()
    
    #if DEBUG || BETA
    func overrideFeature(_ feature: FeatureFlag, with value: Bool) {
        Self.overrides.overrides[feature] = value
    }
    #endif
    
    private init(provider: FeatureFlagProvider) {
        // This prevents users that had the beta app to get invalid flags after updating to appstore version
        #if RELEASE
        Self.overrides.clear()
        #endif
        self.provider = provider
        self.provider.onFeatureListChange = { [weak self] in self?.updateList() }
        updateList()
    }
    
    private func updateList() {
        enabledFeatures = FeatureFlag.allCases.filter { provider.isFeatureOn($0) ?? false }
        Log.info("Updated feature list: \(enabledFeatures)")
    }
    
    private struct AllFeaturesOn: FeatureFlagProvider {
        var onFeatureListChange: (() -> Void)?
        func isFeatureOn(_ feature: FeatureFlag) -> Bool? { true }
    }
}

fileprivate class CompositeFeatureFlagProvider: FeatureFlagProvider {
    var onFeatureListChange: (() -> Void)? {
        didSet {
            for var child in children {
                child.onFeatureListChange = onFeatureListChange
            }
        }
    }
    
    private var children: [FeatureFlagProvider]
    
    init(children: [FeatureFlagProvider]) {
        self.children = children
    }
    
    func isFeatureOn(_ feature: FeatureFlag) -> Bool? {
        children.compactMap { $0.isFeatureOn(feature) }.first
    }
}
