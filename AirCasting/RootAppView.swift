//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI

struct RootAppView: View {
    @ObservedObject var userAuthenticationSession = UserAuthenticationSession()
    @AppStorage("onBoardingKey", store: UserDefaults.standard) var passedOnboarding: Bool = false
    
    let persistenceController = PersistenceController.shared
    let bluetoothManager = BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)))
    let microphoneManager = MicrophoneManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared))
    let urlProvider = UserDefaultsBaseURLProvider()
    var body: some View {
        if userAuthenticationSession.isLoggedIn {
            mainAppView
        } else if !userAuthenticationSession.isLoggedIn && passedOnboarding  {
            NavigationView {
                SignInView(userSession: userAuthenticationSession, urlProvider: urlProvider).environmentObject(userAuthenticationSession)
            }
        } else {
            GetStarted(completion: {
                passedOnboarding = true
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
