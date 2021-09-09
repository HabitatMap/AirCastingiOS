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
    @StateObject private var lifeTimeEventsProvider = LifeTimeEventsProvider()
    @StateObject private var userSettings = UserSettings()
    @StateObject private var locationTracker = LocationTracker(locationManager: CLLocationManager())
    @StateObject private var userRedirectionSettings = DefaultSettingsRedirection()
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var microphoneManager: MicrophoneManager
    
    var sessionSynchronizer: SessionSynchronizer
    let persistenceController: PersistenceController
    var defaultSessionSynchronizer: DefaultSessionSynchronizer
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
                            measurementStreamStorage: measurementStreamStorage, defaultSessionSynchronizer: defaultSessionSynchronizer)
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
        .environmentObject(bluetoothManager)
        .environmentObject(userAuthenticationSession)
        .environmentObject(persistenceController)
        .environmentObject(networkChecker)
        .environmentObject(lifeTimeEventsProvider)
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
    var defaultSessionSynchronizer: DefaultSessionSynchronizer
    
    @EnvironmentObject private var persistenceController: PersistenceController
    @EnvironmentObject private var urlProvider: UserDefaultsBaseURLProvider
    @EnvironmentObject private var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    
    var body: some View {
        MainTabBarView(measurementUpdatingService: downloadService,
                       urlProvider: urlProvider,
                       measurementStreamStorage: measurementStreamStorage,
                       sessionStoppableFactory: sessionStoppableFactory,
                       sessionSynchronizer: sessionSynchronizer,
                       sessionContext: CreateSessionContext(), defaultSessionSynchronizer: defaultSessionSynchronizer)
            .environmentObject(airBeamConnectionController)
    }
}

#if DEBUG
struct RootAppView_Previews: PreviewProvider {
    static var previews: some View {
        RootAppView(sessionSynchronizer: DummySessionSynchronizer(), persistenceController: PersistenceController(inMemory: true), defaultSessionSynchronizer: SessionSynchronizationViewModel())
    }
}
#endif
