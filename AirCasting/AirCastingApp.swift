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

    init() {
        #if !DEBUG
        FirebaseApp.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootAppView()
        }
    }
}
