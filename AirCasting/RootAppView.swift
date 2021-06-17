//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI

struct RootAppView: View {
    @ObservedObject var userAuthenticationSession = UserAuthenticationSession()

    let persistenceController = PersistenceController.shared
    let bluetoothManager = BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared)))
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
                        persistenceController: persistenceController))
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
