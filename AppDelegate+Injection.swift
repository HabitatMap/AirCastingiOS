// Created by Lunar on 10/01/2022.
//

import Foundation

import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        main.register { PersistenceController(inMemory: false) }
            .implements(SessionsFetchable.self)
            .implements(SessionRemovable.self)
            .implements(SessionInsertable.self)
            .scope(.application)
        
        main.register { CoreDataMeasurementStreamStorage() as MeasurementStreamStorage }.scope(.cached)
        main.register { MicrophoneManager(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
        main.register { AveragingService(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
        main.register { MobilePeripheralSessionManager(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
        main.register { BluetoothManager(mobilePeripheralSessionManager: Resolver.resolve()) }
            .implements(BluetoothConnector.self)
            .scope(.cached)
        main.register { DefaultBluetoothHandler() as BluetoothHandler }
        
        main.register { DefaultRemoteNotificationRouter() }
            .implements(RemoteNotificationRouter.self)
            .implements(RemoteNotificationsHandler.self)
            .scope(.application)
        main.register { OverridingFeatureFlagProvider() }.scope(.cached)
        main.register { DefaultFeatureFlagProvider() }.scope(.cached)
        #if !DEBUG
        main.register { FirebaseFeatureFlagProvider() }.scope(.cached)
        #endif
        main.register {
            #if DEBUG
            CompositeFeatureFlagProvider(children: [
                Resolver.resolve(OverridingFeatureFlagProvider.self),
                AllFeaturesOn()
            ]) as FeatureFlagProvider
            #elseif BETA
            CompositeFeatureFlagProvider(children: [
                Resolver.resolve(OverridingFeatureFlagProvider.self),
                Resolver.resolve(FirebaseFeatureFlagProvider.self),
                Resolver.resolve(DefaultFeatureFlagProvider.self)
            ]) as FeatureFlagProvider
            #else
            CompositeFeatureFlagProvider(children: [
                Resolver.resolve(FirebaseFeatureFlagProvider.self),
                Resolver.resolve(DefaultFeatureFlagProvider.self)
            ]) as FeatureFlagProvider
            #endif
        }
        main.register { FeatureFlagsViewModel() }.scope(.application)
    }
    
    // MARK: - Composition helpers
    
    private class CompositeFeatureFlagProvider: FeatureFlagProvider {
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
    
    private struct AllFeaturesOn: FeatureFlagProvider {
        var onFeatureListChange: (() -> Void)?
        func isFeatureOn(_ feature: FeatureFlag) -> Bool? { true }
    }
}
