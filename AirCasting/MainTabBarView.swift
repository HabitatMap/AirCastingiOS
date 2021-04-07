//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI
import Firebase

struct MainTabBarView: View {

    @StateObject var downloadFixedMeasurementService = DownloadMeasurementsService()
    
    var body: some View {
        TabView {
            dashboardTab
            createSessionTab
            settingsTab
        }
        .onAppear {
            downloadFixedMeasurementService.start()
        }
    }
    
    // Tab Bar views
    private var dashboardTab: some View {
        NavigationView {
            DashboardView()
        }
        .tabItem {
            Image(systemName: "house")
        }
    }
    private var createSessionTab: some View {
        // TO DO: Change starting view
        ChooseSessionTypeView()
        .tabItem {
            Image(systemName: "plus")
        }
    }
    private var settingsTab: some View {
        SettingsView()
            .tabItem {
                Image(systemName: "gearshape")
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabBarView()
    }
}
