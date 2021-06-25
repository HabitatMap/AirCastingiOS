//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI

struct RootAppView: View {
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    let sessionSynchronizer: SessionSynchronizer
    let persistenceController: PersistenceController
    let bluetoothManager = BluetoothManager()
    let microphoneManager = MicrophoneManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared))
    
    var body: some View {
        if userAuthenticationSession.isLoggedIn {
            mainAppView
        } else {
            NavigationView {
                SignInView(userAuthenticationSession: userAuthenticationSession).environmentObject(userAuthenticationSession)
            }
        }
    }
    
    var mainAppView: some View {
        MainTabBarView(measurementUpdatingService: DownloadMeasurementsService(
                        authorisationService: userAuthenticationSession,
                        persistenceController: persistenceController),
                       sessionSynchronizer: sessionSynchronizer)
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
        RootAppView(sessionSynchronizer: DummySessionSynchronizer(), persistenceController: .shared)
    }
}
#endif
