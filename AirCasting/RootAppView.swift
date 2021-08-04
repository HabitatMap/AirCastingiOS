//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import CoreLocation

struct RootAppView: View {

    let networkChecker = NetworkChecker(connectionAvailable: false)
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @ObservedObject var userRedirectionSettings = DefaultSettingsRedirection()
    let sessionSynchronizer: SessionSynchronizer
    let persistenceController: PersistenceController
    let bluetoothManager = BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)))
    @ObservedObject var lifeTimeEventsProvider = LifeTimeEventsProvider()
    @ObservedObject var userSettings = UserSettings()
    @ObservedObject var locationTracker = LocationTracker(locationManager: CLLocationManager())
    
    @ObservedObject var microphoneManager = MicrophoneManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared))
    let urlProvider = UserDefaultsBaseURLProvider()
    var body: some View {
        if userAuthenticationSession.isLoggedIn {
            mainAppView
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

    var mainAppView: some View {
        MainTabBarView(measurementUpdatingService: DownloadMeasurementsService(
                        authorisationService: userAuthenticationSession,
                        persistenceController: persistenceController,
                        baseUrl: urlProvider),
                       urlProvider: urlProvider,
                       sessionSynchronizer: sessionSynchronizer, sessionContext: CreateSessionContext())
            .environmentObject(bluetoothManager)
            .environmentObject(userAuthenticationSession)
            .environmentObject(persistenceController)
            .environmentObject(networkChecker)
            .environmentObject(lifeTimeEventsProvider)
            .environmentObject(userSettings)
            .environmentObject(locationTracker)
            .environmentObject(microphoneManager)
            .environmentObject(userRedirectionSettings)
            .environment(\.managedObjectContext, persistenceController.viewContext)
    }
}

#if DEBUG
struct RootAppView_Previews: PreviewProvider {
    static var previews: some View {
        RootAppView(sessionSynchronizer: DummySessionSynchronizer(), persistenceController: .shared)
    }
}
#endif
