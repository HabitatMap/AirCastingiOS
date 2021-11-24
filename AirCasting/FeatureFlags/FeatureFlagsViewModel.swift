import Foundation

class FeatureFlagsViewModel: ObservableObject {
    @Published var enabledFeatures: [FeatureFlag] = []
    
    private var mainProvider: FeatureFlagProvider
    private var fallbackProvider: FeatureFlagProvider
    
    static let shared: FeatureFlagsViewModel = {
        return .init(
            mainProvider: DefaultFeatureFlagProvider(),
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
}
