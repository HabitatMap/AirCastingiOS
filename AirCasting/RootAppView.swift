//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import Firebase

struct RootAppView: View {
    
    let persistenceController = PersistenceController.shared
    @ObservedObject var bluetoothManager = BluetoothManager()
    @AppStorage(UserDefaults.AUTH_TOKEN_KEY) var authToken: String?
    var isLoggedIn: Bool { authToken != nil }    
    
    var body: some View {
        if isLoggedIn {
            mainAppView
        } else {
            NavigationView {
                SignInView()
            }
        }
    }
    
    var mainAppView: some View {
        MainTabBarView()
            .onAppear {
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
            }
            .environmentObject(bluetoothManager)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}

struct RootAppView_Previews: PreviewProvider {
    static var previews: some View {
        RootAppView()
    }
}
