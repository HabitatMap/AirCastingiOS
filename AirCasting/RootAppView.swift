//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI

class Dependancies {
    
}

struct RootAppView: View {
    @ObservedObject var userAuthenticationSession = UserAuthenticationSession()
    @ObservedObject var lifeTimeEventsProvider = UserDefaultProtocol()

    let persistenceController = PersistenceController.shared
    let bluetoothManager = BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)))
    let microphoneManager = MicrophoneManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared))
    let urlProvider = UserDefaultsBaseURLProvider()
    var airBeamConnectionController = DefaultAirBeamConnectionController(connectingAirBeamServices: ConnectingAirBeamServicesBluetooth(bluetoothConnector: bluetoothManager))
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
                        baseUrl: urlProvider), urlProvider: urlProvider)
            .environmentObject(bluetoothManager)
            .environmentObject(microphoneManager)
            .environmentObject(userAuthenticationSession)
            .environmentObject(persistenceController)
            .environmentObject(airBeamConnectionController)
            .environment(\.managedObjectContext, persistenceController.viewContext)
    }
}

#if DEBUG
struct RootAppView_Previews: PreviewProvider {
    static var previews: some View {
        RootAppView()
    }
}
#endif
