// Created by Lunar on 10/01/2022.
//

import Foundation
import CoreLocation
import Resolver

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        // MARK: Persistence
        main.register { PersistenceController(inMemory: false) }
            .implements(SessionsFetchable.self)
            .implements(SessionRemovable.self)
            .implements(SessionInsertable.self)
            .scope(.application)
        main.register { CoreDataMeasurementStreamStorage() as MeasurementStreamStorage }.scope(.cached)
        main.register { DefaultFileLineReader() as FileLineReader }
        
        // MARK: - Networking
        main.register { URLSession.shared as APIClient }.scope(.application)
        main.register { UserAuthenticationSession() }
            .implements(RequestAuthorisationService.self)
            .implements(Deauthorizable.self)
            .scope(.application)
        main.register { DefaultHTTPResponseValidator() as HTTPResponseValidator }
        main.register { UserDefaultsURLProvider() as URLProvider }
        main.register { DefaultNetworkChecker() as NetworkChecker }.scope(.application)
        
        // MARK: - Feature flags
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
        
        // MARK: - Session sync
        main.register { SessionSynchronizationService() as SessionSynchronizationContextProvidable }
        main.register { SessionDownloadService() }
            .implements(SessionDownstream.self)
            .implements(MeasurementsDownloadable.self)
        main.register { SessionUploadService() as SessionUpstream }
        main.register { SessionSynchronizationDatabase() as SessionSynchronizationStore }
        main.register {
            ScheduledSessionSynchronizerProxy(controller: SessionSynchronizationController(), scheduler: DispatchQueue.global()) as SessionSynchronizer
        }.scope(.application)
        
        // MARK: - Location handling
        main.register { LocationTracker(locationManager: CLLocationManager()) }.scope(.application)
        main.register { DefaultLocationHandler() as LocationHandler }.scope(.application)
        
        // MARK: - Settings
        main.register { UserSettings(userDefaults: .standard) }.scope(.cached)
        
        // MARK: - Services
        main.register { DownloadMeasurementsService() }.implements(MeasurementUpdatingService.self).scope(.cached)
        main.register { DefaultSettingsRedirection() as SettingsRedirection }.scope(.application)
        main.register { LifeTimeEventsProvider(userDefaults: .standard) }.implements(FirstRunInfoProvidable.self).scope(.application)
        main.register { MicrophoneManager(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
        main.register { AveragingService(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
        main.register { MobilePeripheralSessionManager(measurementStreamStorage: Resolver.resolve()) }.scope(.cached)
        main.register { BluetoothManager(mobilePeripheralSessionManager: Resolver.resolve()) }
            .implements(BluetoothConnector.self)
            .scope(.cached)
        main.register { DefaultBluetoothHandler() as BluetoothHandler }
        main.register { UserState() }.scope(.application)
        main.register { SyncedMeasurementsDownloadingService() as SyncedMeasurementsDownloader }
        main.register { ConnectingAirBeamServicesBluetooth() as ConnectingAirBeamServices }
        main.register { DefaultAirBeamConnectionController() as AirBeamConnectionController }
        main.register { DefaultSessionUpdateService() as SessionUpdateService }
        main.register { DefaultLogoutController(sessionStorage: SessionStorage()) as LogoutController }
        
        // MARK: - Session stopping
        
        main.register { (_, args) in
            getSessionStopper(for: args())
        }
        
        func getSessionStopper(for session: SessionEntity) -> SessionStoppable {
            let stopper = matchStopper(for: session)
            if session.locationless {
                if session.deviceType == .MIC {
                    return MicrophoneSessionStopper(uuid: session.uuid)
                }
                return StandardSesssionStopper(uuid: session.uuid)
            }
            return SyncTriggeringSesionStopperDecorator(stoppable: stopper, synchronizer: Resolver.resolve())
        }
        
        func matchStopper(for session: SessionEntity) -> SessionStoppable {
            switch session.deviceType {
            case .MIC: return MicrophoneSessionStopper(uuid: session.uuid)
            case .AIRBEAM3: return StandardSesssionStopper(uuid: session.uuid)
            case .none: return StandardSesssionStopper(uuid: session.uuid)
            }
        }
        
        // MARK: - SDSync
        main.register { SDSyncController() }.scope(.cached)
        main.register { SDCardMobileSessionsSavingService() as SDCardMobileSessionssSaver }
        main.register { UploadFixedSessionAPIService() }
        main.register { SDCardFixedSessionsSavingService() }
        main.register { SDSyncFileValidationService() as SDSyncFileValidator }
        main.register { SDSyncFileWritingService(bufferThreshold: 1000) as SDSyncFileWriter }
        main.register { BluetoothSDCardAirBeamServices() as SDCardAirBeamServices }
        
        // MARK: - Notes
        main.register { (_, args) in
            NotesHandlerDefault(sessionUUID: args()) as NotesHandler
        }
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
