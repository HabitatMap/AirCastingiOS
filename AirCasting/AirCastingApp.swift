//
//  AirCastingApp.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI
import Firebase

@main
struct AirCastingApp: App {
    
    let api = AuthorizationAPI()
    
    var body: some Scene {
        WindowGroup {
            MainTabBarView()
//            SelectPeripheralView()
//            TurnOnBluetoothView()
                .onAppear {
                    FirebaseApp.configure()
                }
        }
    }
}
