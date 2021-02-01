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
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                // GraphView()
                // Dashboard()
                SessionCell()
                
            }
            .onAppear {
                
            }
        }
    }
}
