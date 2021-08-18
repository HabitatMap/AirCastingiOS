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
    @StateObject private var bluetoothManager = BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)))
    @StateObject private var lifeTimeEventsProvider = LifeTimeEventsProvider()
    @StateObject private var userSettings = UserSettings()
    @StateObject private var locationTracker = LocationTracker(locationManager: CLLocationManager())
    @StateObject private var userRedirectionSettings = DefaultSettingsRedirection()
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    var sessionSynchronizer: SessionSynchronizer
    let persistenceController: PersistenceController
    let urlProvider = UserDefaultsBaseURLProvider()
    let networkChecker = NetworkChecker(connectionAvailable: false)
    
    var body: some View {
        ZStack {
            if userAuthenticationSession.isLoggedIn,
               let airBeamConnectionController = airBeamConnectionController {
                MainAppView(airBeamConnectionController: airBeamConnectionController,
                            sessionSynchronizer: sessionSynchronizer)
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
        }
    }
    
}

struct MainAppView: View {
    
    let airBeamConnectionController: DefaultAirBeamConnectionController
    let sessionSynchronizer: SessionSynchronizer
    private let measurementStreamStorage: MeasurementStreamStorage = CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)
    @EnvironmentObject var persistenceController: PersistenceController
    @EnvironmentObject var urlProvider: UserDefaultsBaseURLProvider
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var microphoneManager: MicrophoneManager
    
    var body: some View {
        let sessionStoppableFactory = SessionStoppableFactoryDefault(microphoneManager: microphoneManager,
                                                                     measurementStreamStorage: measurementStreamStorage,
                                                                     synchronizer: sessionSynchronizer)
        MainTabBarView(measurementUpdatingService: DownloadMeasurementsService(
                        authorisationService: userAuthenticationSession,
                        persistenceController: persistenceController,
                        baseUrl: urlProvider), urlProvider: urlProvider, measurementStreamStorage: measurementStreamStorage, sessionStoppableFactory: sessionStoppableFactory, sessionSynchronizer: sessionSynchronizer, sessionContext: CreateSessionContext())
            .environmentObject(airBeamConnectionController)
    }
}

#if DEBUG
struct RootAppView_Previews: PreviewProvider {
    static var previews: some View {
        RootAppView(sessionSynchronizer: DummySessionSynchronizer(), persistenceController: PersistenceController(inMemory: true))
    }
}
#endif
