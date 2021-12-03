import Foundation

class FeatureFlagsViewModel: ObservableObject {
    @Published var enabledFeatures: [FeatureFlag] = []
    
    private var mainProvider: FeatureFlagProvider
    private var fallbackProvider: FeatureFlagProvider
    
    private static let mainProvider: FeatureFlagProvider = {
        #if DEBUG
        Log.info("Debug build, enabling all fatures")
        return AllFeaturesOn()
        #else
        Log.info("Release build, using firebase config for features")
        return FirebaseFeatureFlagProvider(notificationsRouter: DefaultRemoteNotificationRouter.shared)
        #endif
    }()
    
    static let shared: FeatureFlagsViewModel = {
        return .init(
            mainProvider: FeatureFlagsViewModel.mainProvider,
            fallbackProvider: DefaultFeatureFlagProvider()
        )
    }()
    
    private init(mainProvider: FeatureFlagProvider, fallbackProvider: FeatureFlagProvider) {
        self.mainProvider = mainProvider
        self.fallbackProvider = fallbackProvider
        self.mainProvider.onFeatureListChange = { [weak self] in self?.updateList() }
        self.fallbackProvider.onFeatureListChange = { [weak self] in self?.updateList() }
        updateList()
    }
    
    private func updateList() {
        enabledFeatures = FeatureFlag.allCases.filter {
            mainProvider.isFeatureOn($0) ?? (fallbackProvider.isFeatureOn($0) ?? false)
        }
        Log.info("Updated feature list: \(enabledFeatures)")
    }
    
    private struct AllFeaturesOn: FeatureFlagProvider {
        var onFeatureListChange: (() -> Void)?
        func isFeatureOn(_ feature: FeatureFlag) -> Bool? { true }
    }
}
