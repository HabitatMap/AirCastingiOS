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
    
    @StateObject private var userSettings = UserSettings()
    @StateObject private var userRedirectionSettings = DefaultSettingsRedirection()
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var lifeTimeEventsProvider: LifeTimeEventsProvider
    @Injected private var averagingService: AveragingService
    
    let locationTracker = LocationTracker(locationManager: CLLocationManager())
    var sessionSynchronizer: SessionSynchronizer
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
        .environmentObject(userAuthenticationSession)
        .environmentObject(userSettings)
        .environmentObject(locationTracker)
        .environmentObject(userRedirectionSettings)
        .environment(\.managedObjectContext, Resolver.resolve(PersistenceController.self).viewContext) //TODO: Where is this used??
        .onAppear {
            airBeamConnectionController = DefaultAirBeamConnectionController(connectingAirBeamServices: ConnectingAirBeamServicesBluetooth())
            
            sessionStoppableFactory = SessionStoppableFactoryDefault(measurementStreamStorage: measurementStreamStorage,
                                                                     synchronizer: sessionSynchronizer)
            downloadService = DownloadMeasurementsService(authorisationService: userAuthenticationSession,
                                                          baseUrl: urlProvider)
            let mobileSessionsService = SDCardMobileSessionsSavingService(measurementStreamStorage: measurementStreamStorage,
                                                                          fileLineReader: DefaultFileLineReader())
            
            let apiService = UploadFixedSessionAPIService(authorisationService: userAuthenticationSession,
                                                          baseUrlProvider: urlProvider)
            
            let fixedSessionsService = SDCardFixedSessionsSavingService(apiService: apiService)
            
            sdSyncController = SDSyncController(airbeamServices: BluetoothSDCardAirBeamServices(userAuthenticationSession: userAuthenticationSession),
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
    @InjectedObject private var user: UserState
    @EnvironmentObject private var userAuthenticationSession: UserAuthenticationSession
    
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
