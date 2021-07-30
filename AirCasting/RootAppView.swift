//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI

class Dependancies {
    @ObservedObject var userAuthenticationSession = UserAuthenticationSession()
    @ObservedObject var lifeTimeEventsProvider = UserDefaultProtocol()

    let persistenceController = PersistenceController.shared
    let bluetoothManager = BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)))
    let microphoneManager = MicrophoneManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared))
    let urlProvider = UserDefaultsBaseURLProvider()
    lazy var airBeamConnectionController = DefaultAirBeamConnectionController(connectingAirBeamServices: ConnectingAirBeamServicesBluetooth(bluetoothConnector: bluetoothManager))
}

struct RootAppView: View {
    let dependancies = Dependancies()
    var body: some View {
        if dependancies.userAuthenticationSession.isLoggedIn {
            mainAppView
        } else if !dependancies.userAuthenticationSession.isLoggedIn && dependancies.lifeTimeEventsProvider.hasEverPassedOnBoarding {
            NavigationView {
                CreateAccountView(completion: { self.dependancies.lifeTimeEventsProvider.hasEverLoggedIn = true }, userSession: dependancies.userAuthenticationSession, baseURL: dependancies.urlProvider).environmentObject(dependancies.lifeTimeEventsProvider)
            }
        } else {
            GetStarted(completion: {
                self.dependancies.lifeTimeEventsProvider.hasEverPassedOnBoarding = true
            })
        }
    }

    var mainAppView: some View {
        MainTabBarView(measurementUpdatingService: DownloadMeasurementsService(
                        authorisationService: dependancies.userAuthenticationSession,
                        persistenceController: dependancies.persistenceController,
                        baseUrl: dependancies.urlProvider), urlProvider: dependancies.urlProvider)
            .environmentObject(dependancies.bluetoothManager)
            .environmentObject(dependancies.microphoneManager)
            .environmentObject(dependancies.userAuthenticationSession)
            .environmentObject(dependancies.persistenceController)
            .environmentObject(dependancies.airBeamConnectionController)
            .environment(\.managedObjectContext, dependancies.persistenceController.viewContext)
    }
}

#if DEBUG
struct RootAppView_Previews: PreviewProvider {
    static var previews: some View {
        RootAppView()
    }
}
#endif
