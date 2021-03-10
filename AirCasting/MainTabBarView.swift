//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI

struct MainTabBarView: View {

    @StateObject var sessionContext = CreateSessionContext()
    
    var body: some View {
        TabView {
            dashboardTab
            createSessionTab
            settingsTab
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
        NavigationView {
            // TO DO: Change starting view
            ChooseSessionTypeView()
        }
        .environmentObject(sessionContext)
        .tabItem {
            Image(systemName: "plus")
        }
    }
    private var settingsTab: some View {
        Color.aircastingGray
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
