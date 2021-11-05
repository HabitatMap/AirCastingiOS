//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import CoreLocation

struct RootAppView: View {
    
    @State private var airBeamConnectionController: DefaultAirBeamConnectionController?
    @State private var measurementStreamStorage: MeasurementStreamStorage = CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)
    @State private var sessionStoppableFactory: SessionStoppableFactoryDefault?
    @State private var downloadService: DownloadMeasurementsService?
    @StateObject private var bluetoothManager = BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)))
    
    @StateObject private var userSettings = UserSettings()
    @StateObject private var userRedirectionSettings = DefaultSettingsRedirection()
    @StateObject private var userState = UserState()
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var microphoneManager: MicrophoneManager
    @EnvironmentObject var lifeTimeEventsProvider: LifeTimeEventsProvider
    
    let locationTracker = LocationTracker(locationManager: CLLocationManager())
    var sessionSynchronizer: SessionSynchronizer
    let persistenceController: PersistenceController
    let urlProvider = UserDefaultsBaseURLProvider()
    let networkChecker = NetworkChecker(connectionAvailable: false)
    
    var body: some View {
        ZStack {
            if userAuthenticationSession.isLoggedIn,
               let airBeamConnectionController = airBeamConnectionController,
               let sessionStoppableFactory = sessionStoppableFactory,
               let downloadService = downloadService {
                MainAppView(airBeamConnectionController: airBeamConnectionController,
                            sessionSynchronizer: sessionSynchronizer,
                            sessionStoppableFactory: sessionStoppableFactory,
                            downloadService: downloadService,
                            measurementStreamStorage: measurementStreamStorage,
                            locationHandler: DefaultLocationHandler(locationTracker: locationTracker))
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
        .environmentObject(persistenceController)
        .environmentObject(networkChecker)
        .environmentObject(userSettings)
        .environmentObject(locationTracker)
        .environmentObject(userRedirectionSettings)
        .environmentObject(urlProvider)
        .environment(\.managedObjectContext, persistenceController.viewContext)
        .onAppear {
            airBeamConnectionController = DefaultAirBeamConnectionController(connectingAirBeamServices: ConnectingAirBeamServicesBluetooth(bluetoothConnector: bluetoothManager))
            
            sessionStoppableFactory = SessionStoppableFactoryDefault(microphoneManager: microphoneManager,
                                                                         measurementStreamStorage: measurementStreamStorage,
                                                                         synchronizer: sessionSynchronizer,
                                                                         bluetoothManager: bluetoothManager)
            downloadService = DownloadMeasurementsService(authorisationService: userAuthenticationSession,
                                                          persistenceController: persistenceController,
                                                          baseUrl: urlProvider)
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
    
    @EnvironmentObject private var persistenceController: PersistenceController
    @EnvironmentObject private var urlProvider: UserDefaultsBaseURLProvider
    @EnvironmentObject private var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    @EnvironmentObject private var user: UserState
    
    @State private var isUserLoggingOut: Bool = false
    
    var body: some View {
        LoadingView(isShowing: $user.isLoggingOut, activityIndicatorText: Strings.MainTabBarView.loggingOut) {
            MainTabBarView(measurementUpdatingService: downloadService,
                           urlProvider: urlProvider,
                           measurementStreamStorage: measurementStreamStorage,
                           sessionStoppableFactory: sessionStoppableFactory,
                           sessionSynchronizer: sessionSynchronizer,
                           sessionContext: CreateSessionContext(),
                           coreDataHook: CoreDataHook(context: persistenceController.viewContext), locationHandler: locationHandler)
                .environmentObject(airBeamConnectionController)
        }
    }
}

#if DEBUG
struct RootAppView_Previews: PreviewProvider {
    static var previews: some View {
        RootAppView(sessionSynchronizer: DummySessionSynchronizer(), persistenceController: PersistenceController(inMemory: true))
    }
}
#endif
