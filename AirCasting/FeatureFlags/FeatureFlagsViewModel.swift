import Foundation

class FeatureFlagsViewModel: ObservableObject {
    @Published var enabledFeatures: [FeatureFlag] = []
    
    private var provider: FeatureFlagProvider
    static private let overrides = OverridingFeatureFlagProvider()
    
    static let shared: FeatureFlagsViewModel = {
        return .init(
            provider: CompositeFeatureFlagProvider(children: [
                FeatureFlagsViewModel.overrides,
                FirebaseFeatureFlagProvider(notificationsRouter: DefaultRemoteNotificationRouter.shared),
                DefaultFeatureFlagProvider()
            ])
        )
    }()
    
    #if DEBUG || BETA
    func overrideFeature(_ feature: FeatureFlag, with value: Bool) {
        Self.overrides.overrides[feature] = value
    }
    #endif
    
    private init(provider: FeatureFlagProvider) {
        self.provider = provider
        self.provider.onFeatureListChange = { [weak self] in self?.updateList() }
        updateList()
    }
    
    private func updateList() {
        enabledFeatures = FeatureFlag.allCases.filter { provider.isFeatureOn($0) ?? false }
        Log.info("Updated feature list: \(enabledFeatures)")
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
