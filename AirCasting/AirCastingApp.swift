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
    @ObservedObject var bluetoothManager = BluetoothManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabBarView()
                .onAppear {
                    FirebaseApp.configure()
                }
                .environmentObject(bluetoothManager)
        }
    }
}
