import Foundation

class FeatureFlagsViewModel: ObservableObject {
    @Published var enabledFeatures: [FeatureFlag] = []
    
    private var provider: FeatureFlagProvider
    #if DEBUG || BETA
    static private let overrides = OverridingFeatureFlagProvider()
    #endif
    
    static let shared: FeatureFlagsViewModel = {
        // For debug builds we have all features turned on with possibility to switch flags inside the app
        #if DEBUG
        return .init(
            provider: CompositeFeatureFlagProvider(children: [
                FeatureFlagsViewModel.overrides,
                AllFeaturesOn()
            ])
        )
        // For beta builds we have firebase-based features with possibility to switch flags inside the app
        #elseif BETA
        return .init(
            provider: CompositeFeatureFlagProvider(children: [
                FeatureFlagsViewModel.overrides,
                FirebaseFeatureFlagProvider(notificationsRouter: DefaultRemoteNotificationRouter.shared),
                DefaultFeatureFlagProvider()
            ])
        )
        // For release builds we have firebase-based features with no possibility of switching flags inside the app
        #else
        return .init(
            provider: CompositeFeatureFlagProvider(children: [
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
