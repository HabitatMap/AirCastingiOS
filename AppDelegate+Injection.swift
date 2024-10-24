// Created by Lunar on 10/01/2022.
//

import Foundation
import CoreLocation
import Resolver
import DeviceKit
import Firebase

extension Resolver: ResolverRegistering {
    public static func registerAllServices() {
        // We do Firebase config here as this is actually the first place that gets called in the app.
        FirebaseApp.configure()
        
        main.register { PersistenceController(inMemory: false) }
        .implements(SessionsFetchable.self)
        .implements(SessionRemovable.self)
        .implements(SessionInsertable.self)
        .implements(SessionUpdateable.self)
        .scope(.application)
        main.register { (_, args) in
            let deviceID: String = args()
            return deviceID.isMini ? MiniSDCardMeasurementsParser() : SDCardMeasurementsParser() as SDMeasurementsParser
        }
        main.register { DefaultSessionNotesStorage() as SessionNotesStorage }.scope(.cached)
        main.register { DefaultSessionDeletingStorage() as SessionDeletingStorage }.scope(.cached)
        main.register { DefaultSDSyncMeasurementsStorage() as SDSyncMeasurementsStorage }.scope(.cached)
        main.register { DefaultMobileSessionRecordingStorage() as MobileSessionRecordingStorage }.scope(.cached)
        main.register { DefaultMobileSessionFinishingStorage() as MobileSessionFinishingStorage }
        main.register { DefaultSessionCreatingStorage() as SessionCreatingStorage }
        main.register { DefaultSessionFollowingStorage() as SessionFollowingStorage }
        main.register { DefaultSessionEditingStorage() as SessionEditingStorage }
        main.register { DefaultSyncingMeasurementsStorage() as SyncingMeasurementsStorage }
        main.register { (_, _) -> UIStorage in
            let context = Resolver.resolve(PersistenceController.self).editContext
            return CoreDataUIStorage(context: context)
        }.scope(.cached)
        main.register { (_, _) -> SessionStorage in
            let context = Resolver.resolve(PersistenceController.self).editContext
            return CoreDataSessionStorage(context: context)
        }.scope(.cached)
        main.register { (_, _) -> SessionEntityStore in
            let context = Resolver.resolve(PersistenceController.self).editContext
            return DefaultSessionEntityStore(context: context)
        }
        main.register { (_, _) -> AveragingServiceStorage in
            let context = Resolver.resolve(PersistenceController.self).editContext
            return DefaultAveragingServiceStorage(context: context)
        }.scope(.cached)
        main.register { DefaultFileLineReader() as FileLineReader }
        main.register { SessionDataEraser() as DataEraser }

        // MARK: - Networking
        main.register { URLSession.shared as APIClient }.scope(.application)
        main.register { UserAuthenticationSession() }
        .implements(RequestAuthorisationService.self)
        .implements(Deauthorizable.self)
        .scope(.application)
        main.register { DefaultHTTPResponseValidator() as HTTPResponseValidator }
        main.register { UserDefaultsURLProvider() as URLProvider }
        main.register { DefaultNetworkChecker() as NetworkChecker }.scope(.application)
        main.register { DefaultSingleSessionDownloader() as SingleSessionDownloader }
        main.register { DefaultDormantStreamAlertAPI() as DormantStreamAlertService }

        // MARK: - Feature flags
        main.register { DefaultRemoteNotificationRouter() }
        .implements(RemoteNotificationRouter.self)
        .implements(RemoteNotificationsHandler.self)
        .scope(.application)
        main.register { OverridingFeatureFlagProvider() }.scope(.cached)
        main.register { DefaultFeatureFlagProvider() }.scope(.cached)
        main.register { DeviceFeatureFlagProvider() }.scope(.cached)
#if !DEBUG
        main.register { FirebaseFeatureFlagProvider() }.scope(.cached)
#endif
        main.register {
#if DEBUG
            CompositeFeatureFlagProvider(children: [
                Resolver.resolve(OverridingFeatureFlagProvider.self),
                Resolver.resolve(DeviceFeatureFlagProvider.self),
                AllFeaturesOn()
            ]) as FeatureFlagProvider
#elseif BETA
            CompositeFeatureFlagProvider(children: [
                Resolver.resolve(OverridingFeatureFlagProvider.self),
                Resolver.resolve(DeviceFeatureFlagProvider.self),
                Resolver.resolve(FirebaseFeatureFlagProvider.self),
                Resolver.resolve(DefaultFeatureFlagProvider.self)
            ]) as FeatureFlagProvider
#else
            CompositeFeatureFlagProvider(children: [
                Resolver.resolve(DeviceFeatureFlagProvider.self),
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
            WiFiAwareSessionSynchronizerProxy(
                controller: ScheduledSessionSynchronizerProxy(controller: SessionSynchronizationController(),
                                                              scheduler: DispatchQueue.global())
            )
        }.scope(.application)
            .implements(SessionSynchronizer.self)

        // MARK: - Location handling
        main.register { _ -> LocationTracker in
            let manager = CLLocationManager()
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.allowsBackgroundLocationUpdates = true
            manager.pausesLocationUpdatesAutomatically = false
            return CoreLocationTracker(locationManager: manager) as LocationTracker
        }
        .implements(LocationAuthorization.self)
        .scope(.application)

        main.register { LocationServiceAdapter(tracker: Resolver.resolve()) as LocationService }.scope(.unique)

        // MARK: - Settings
        main.register { UserSettings(userDefaults: .standard) }.scope(.cached)
        main.register { DefaultSettingsController() as SettingsController }


        // MARK: - Services
        main.register { DownloadMeasurementsService() }.implements(MeasurementUpdatingService.self).scope(.cached)
        main.register { DefaultSettingsRedirection() as SettingsRedirection }.scope(.application)
        main.register { LifeTimeEventsProvider(userDefaults: .standard) }.implements(FirstRunInfoProvidable.self).scope(.application)
        main.register { MicrophoneManager() }.scope(.cached)
        main.register { ActiveSessionsAveragingController() }.scope(.cached)
        main.register { MobileAirBeamSessionRecordingController() as BluetoothSessionRecordingController }
            .scope(.application)
        main.register { AirbeamMeasurementsRecordingServices() as MeasurementsRecordingServices }
        main.register { BluetoothManager() }
        .implements(BluetoothCommunicator.self)
        .implements(BluetoothPermisionsChecker.self)
        .implements(BluetoothPeripheralConnectionChecker.self)
        .implements(BluetoothStateHandler.self)
        .implements(BluetoothScanner.self)
        .implements(BluetoothConnectionHandler.self)
        .implements(BluetoothConnectionObservable.self)
        .implements(BluetoothPeripheralConfigurator.self)
        .scope(.cached)
        main.register { UserState() }.scope(.application)
        main.register { SyncedMeasurementsDownloadingService() as SyncedMeasurementsDownloader }
        main.register { ConnectingAirBeamServicesBluetooth() as ConnectingAirBeamServices }
        main.register { DefaultAirBeamConnectionController() as AirBeamConnectionController }
        main.register { DefaultSessionUpdateService() as SessionUpdateService }
        main.register { DefaultLogoutController() as LogoutController }
        main.register { DefaultDeleteAccountController() as DeleteAccountController }
        main.register { DefaultRemoveDataController() as RemoveDataController }
        main.register { DefaultThresholdAlertsController() as ThresholdAlertsController }
        main.register { BluetoothConnectionProtector() as ConnectionProtectable }
        main.register { DefaultMeasurementsSaver() as MeasurementsSavingService }
        main.register { NotificationsManager() }.scope(.application)

        // MARK: - AirBeam configuration
        main.register { (_, args) in
            AirBeam3Configurator(device: args()) as AirBeamConfigurator
        }

        // MARK: - Session stopping
        main.register { (_, args) in
            getSessionStopper(for: args())
        }

        // TODO: Move to a Sessionable when merged in (?)
        func getSessionStopper(for session: DevicedSession) -> SessionStoppable {
            let stopper = matchStopper(for: session)
            if session.locationless {
                if session.deviceType == .MIC {
                    return MicrophoneSessionStopper(uuid: session.uuid)
                }
                return StandardSesssionStopper(uuid: session.uuid)
            }
            return SyncTriggeringSesionStopperDecorator(stoppable: stopper, synchronizer: Resolver.resolve())
        }

        func matchStopper(for session: DevicedSession) -> SessionStoppable {
            switch session.deviceType {
            case .MIC: return MicrophoneSessionStopper(uuid: session.uuid)
            case .AIRBEAM: return StandardSesssionStopper(uuid: session.uuid)
            case .none: return StandardSesssionStopper(uuid: session.uuid)
            }
        }

        // MARK: - SDSync
        main.register { SDSyncController() }.scope(.cached)
        main.register { SDCardMobileSessionsSavingService() as SDCardMobileSessionssSaver }
        main.register { UploadFixedSessionAPIService() }
        main.register { SDCardFixedSessionsUploadingService() }
        main.register { (_, args) in SDSyncFileValidationService(type: args()) as SDSyncFileValidator }
        
        main.register { SDSyncFileWritingService(bufferThreshold: 1000) as SDSyncFileWriter }
        main.register { BluetoothSDCardAirBeamServices() as SDCardAirBeamServices }
        main.register { DefaultMeasurementsAveragingService() as MeasurementsAveragingService }
        main.register { SessionCardUIStateHandlerDefault() as SessionCardUIStateHandler }.scope(.cached)

        // MARK: - Notes
        main.register { (_, args) in
            NotesHandlerDefault(sessionUUID: args()) as NotesHandler
        }

        // MARK: - Update Session Params Service
        main.register { UpdateSessionParamsService() }

        // MARK: - Search and Follow
        main.register { SessionsForLocationDownloaderDefault() as SessionsForLocationDownloader }
        main.register { DefaultStreamDownloader() as StreamDownloader }
        main.register { DefaultSearchAndFollowCompleteScreenService() as SearchAndFollowCompleteScreenService }
        main.register { (_, _) -> ExternalSessionsStore in
            let context = Resolver.resolve(PersistenceController.self).editContext
            return DefaultExternalSessionsStore(context: context)
        }

        // MARK: Unit / value formatting
        main.register { (_, args) in TemperatureThresholdFormatter(threshold: args()) as ThresholdFormatter }
        main.register { TemperatureUnitFormatter() as UnitFormatter }
        main.register { AirBeamMeasurementsDownloaderDefault() as AirBeamMeasurementsDownloader }

        // MARK: - Old measurements remover
        main.register { DefaultRemoveOldMeasurementsService() as RemoveOldMeasurements }

        // MARK: - Microphone
        main.register { CalibratableMicrophoneDecorator(microphone: resolve(AVMicrophone.self)) as Microphone }
            .scope(.application)

        main.register { try! AVMicrophone() }
            .implements(MicrophonePermissions.self)
            .scope(.application)

        main.register { FoundationTimerScheduler() as TimerScheduler }
            .scope(.unique)

        main.register { UserDefaultsMicrophoneCalibraionValueProvider() }
            .implements(MicrophoneCalibraionValueProvider.self)
            .implements(MicrophoneCalibrationValueWritable.self)

        // MARK: Alerts

        main.register { WindowAlertPresenter() as GlobalAlertPresenter }
            .scope(.application)

        // MARK: Reconnect
        main.register { DefaultReconnectionController() as ReconnectionController }
            .scope(.application)
        main.register { SessionManagingReconnectionController() }
            .scope(.application)

        main.register {
            DefaultActiveMobileSessionProvidingService() as ActiveMobileSessionProvidingService
        }.scope(.application)
        
        main.register { DefaultUserTriggeredReconnectionController() as UserTriggeredReconnectionController }

        main.register { _, args in
            guard let args: StandaloneOrigin = args() else { fatalError() }
            switch args {
            case .device: return DefaultStandaloneModeContoller() as StandaloneModeController
            case .user: return UserInitiatedStandaloneModeController() as StandaloneModeController
            }

        }
        // MARK: Timers

        main.register { ScheduledTimerSetter() as ScheduledTimerSettable }.scope(.application)
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

enum StandaloneOrigin {
    case device
    case user
}

protocol DevicedSession {
    var uuid: SessionUUID { get }
    var deviceType: DeviceType? { get }
    var locationless: Bool { get }
}

extension Session: DevicedSession { }
extension SessionEntity: DevicedSession { }
