//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import CoreLocation

class Dependancies {
    let networkChecker = NetworkChecker(connectionAvailable: false)
    let bluetoothManager = BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)))
    let urlProvider = UserDefaultsBaseURLProvider()
    lazy var airBeamConnectionController = DefaultAirBeamConnectionController(connectingAirBeamServices: ConnectingAirBeamServicesBluetooth(bluetoothConnector: bluetoothManager))
}

struct RootAppView: View {
    var dependancies = Dependancies()
    private let measurementStreamStorage: MeasurementStreamStorage = CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)
    @ObservedObject var lifeTimeEventsProvider = LifeTimeEventsProvider()
    @ObservedObject var userSettings = UserSettings()
    @ObservedObject var locationTracker = LocationTracker(locationManager: CLLocationManager())
    @ObservedObject var userRedirectionSettings = DefaultSettingsRedirection()
    let urlProvider = UserDefaultsBaseURLProvider()
    var sessionSynchronizer: SessionSynchronizer
    let persistenceController: PersistenceController
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    var body: some View {
        if userAuthenticationSession.isLoggedIn {
            mainAppView
        } else if !userAuthenticationSession.isLoggedIn && lifeTimeEventsProvider.hasEverPassedOnBoarding {
            NavigationView {
                CreateAccountView(completion: { self.lifeTimeEventsProvider.hasEverLoggedIn = true }, userSession: userAuthenticationSession, baseURL: dependancies.urlProvider).environmentObject(lifeTimeEventsProvider)
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
                            baseUrl: dependancies.urlProvider), urlProvider: dependancies.urlProvider, measurementStreamStorage: measurementStreamStorage, sessionSynchronizer: sessionSynchronizer, sessionContext: CreateSessionContext())
                .environmentObject(dependancies.bluetoothManager)
                .environmentObject(userAuthenticationSession)
                .environmentObject(persistenceController)
                .environmentObject(dependancies.networkChecker)
                .environmentObject(lifeTimeEventsProvider)
                .environmentObject(userSettings)
                .environmentObject(locationTracker)
                .environmentObject(userRedirectionSettings)
                .environmentObject(dependancies.airBeamConnectionController)
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
}

#if DEBUG
struct RootAppView_Previews: PreviewProvider {
    static var previews: some View {
        RootAppView(sessionSynchronizer: DummySessionSynchronizer(), persistenceController: PersistenceController(inMemory: true))
    }
}
#endif
