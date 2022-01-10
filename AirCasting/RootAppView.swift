//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import CoreLocation
import Resolver

struct RootAppView: View {
    
    @State private var airBeamConnectionController: DefaultAirBeamConnectionController?
    @State private var measurementStreamStorage: MeasurementStreamStorage = CoreDataMeasurementStreamStorage()
    @State private var sessionStoppableFactory: SessionStoppableFactoryDefault?
    @State private var downloadService: DownloadMeasurementsService?
    @State private var sdSyncController: SDSyncController?
    @StateObject private var bluetoothManager = BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage()))
    
    @StateObject private var userSettings = UserSettings()
    @StateObject private var userRedirectionSettings = DefaultSettingsRedirection()
    @StateObject private var userState = UserState()
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var lifeTimeEventsProvider: LifeTimeEventsProvider
    @EnvironmentObject var averagingService: AveragingService
    
    let locationTracker = LocationTracker(locationManager: CLLocationManager())
    var sessionSynchronizer: SessionSynchronizer
    let networkChecker = NetworkChecker(connectionAvailable: false)
    let urlProvider: BaseURLProvider
    
    var body: some View {
        ZStack {
            if userAuthenticationSession.isLoggedIn,
               let airBeamConnectionController = airBeamConnectionController,
               let sdSyncController = sdSyncController,
               let sessionStoppableFactory = sessionStoppableFactory,
               let downloadService = downloadService {
                MainAppView(airBeamConnectionController: airBeamConnectionController,
                            sessionSynchronizer: sessionSynchronizer,
                            sessionStoppableFactory: sessionStoppableFactory,
                            downloadService: downloadService,
                            measurementStreamStorage: measurementStreamStorage,
                            locationHandler: DefaultLocationHandler(locationTracker: locationTracker),
                            sdSyncController: sdSyncController,
                            urlProvider: urlProvider)
            } else if !userAuthenticationSession.isLoggedIn && lifeTimeEventsProvider.hasEverPassedOnBoarding {
                NavigationView {
                    CreateAccountView(completion: { self.lifeTimeEventsProvider.hasEverLoggedIn = true }, userSession: userAuthenticationSession, baseURL: urlProvider).environmentObject(lifeTimeEventsProvider)
                }
            } else {
                GetStarted(completion: {
                    self.lifeTimeEventsProvider.hasEverPassedOnBoarding = true
                })
            }
        }
        .environmentObject(userState)
        .environmentObject(bluetoothManager)
        .environmentObject(userAuthenticationSession)
        .environmentObject(networkChecker)
        .environmentObject(userSettings)
        .environmentObject(locationTracker)
        .environmentObject(userRedirectionSettings)
//        .environment(\.managedObjectContext, persistenceController.viewContext)
        .onAppear {
            airBeamConnectionController = DefaultAirBeamConnectionController(connectingAirBeamServices: ConnectingAirBeamServicesBluetooth(bluetoothConnector: bluetoothManager))
            
            sessionStoppableFactory = SessionStoppableFactoryDefault(measurementStreamStorage: measurementStreamStorage,
                                                                     synchronizer: sessionSynchronizer,
                                                                     bluetoothManager: bluetoothManager)
            downloadService = DownloadMeasurementsService(authorisationService: userAuthenticationSession,
                                                          baseUrl: urlProvider)
            let mobileSessionsService = SDCardMobileSessionsSavingService(measurementStreamStorage: measurementStreamStorage,
                                                                          fileLineReader: DefaultFileLineReader())
            
            let apiService = UploadFixedSessionAPIService(authorisationService: userAuthenticationSession,
                                                          baseUrlProvider: urlProvider)
            
            let fixedSessionsService = SDCardFixedSessionsSavingService(apiService: apiService)
            
            sdSyncController = SDSyncController(airbeamServices: BluetoothSDCardAirBeamServices(bluetoothManager: bluetoothManager, userAuthenticationSession: userAuthenticationSession),
                                                fileWriter: SDSyncFileWritingService(bufferThreshold: 10000),
                                                fileValidator: SDSyncFileValidationService(fileLineReader: DefaultFileLineReader()),
                                                fileLineReader: DefaultFileLineReader(),
                                                mobileSessionsSaver: mobileSessionsService,
                                                fixedSessionsSaver: fixedSessionsService,
                                                averagingService: averagingService,
                                                sessionSynchronizer: sessionSynchronizer, measurementsDownloader: SyncedMeasurementsDownloadingService(measurementStreamStorage: measurementStreamStorage, measurementsDownloadingService: downloadService!))
        }
    }
    
}

struct MainAppView: View {
    
    let airBeamConnectionController: DefaultAirBeamConnectionController
    let sessionSynchronizer: SessionSynchronizer
    let sessionStoppableFactory: SessionStoppableFactoryDefault
    let downloadService: DownloadMeasurementsService
    let measurementStreamStorage: MeasurementStreamStorage
    let locationHandler: LocationHandler
    let sdSyncController: SDSyncController
    let urlProvider: BaseURLProvider
    @Injected private var persistenceController: PersistenceController
    
    @EnvironmentObject private var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    @EnvironmentObject private var user: UserState
    
    var body: some View {
        LoadingView(isShowing: $user.isLoggingOut, activityIndicatorText: Strings.MainTabBarView.loggingOut) {
            MainTabBarView(measurementUpdatingService: downloadService,
                           urlProvider: urlProvider,
                           measurementStreamStorage: measurementStreamStorage,
                           sessionStoppableFactory: sessionStoppableFactory,
                           sessionSynchronizer: sessionSynchronizer,
                           sessionContext: CreateSessionContext(),
                           coreDataHook: CoreDataHook(context: persistenceController.viewContext),
                           locationHandler: locationHandler)
                .environmentObject(airBeamConnectionController)
                .environmentObject(sdSyncController)
        }
    }
}
