//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI

struct RootAppView: View {
    
    let persistenceController = PersistenceController.shared
    @ObservedObject var userAuthenticationSession = UserAuthenticationSession()
    @ObservedObject var bluetoothManager = BluetoothManager()
    @ObservedObject var microphoneManager = MicrophoneManager()
    
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
        MainTabBarView(measurementUpdatingService: DownloadMeasurementsService(authorisationService: userAuthenticationSession))
            .environmentObject(bluetoothManager)
            .environmentObject(microphoneManager)
            .environmentObject(userAuthenticationSession)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}

#if DEBUG
struct RootAppView_Previews: PreviewProvider {
    static var previews: some View {
        RootAppView()
    }
}
#endif
