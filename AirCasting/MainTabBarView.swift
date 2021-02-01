//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI

struct MainTabBarView: View {
    
    var body: some View {
        TabView {
            dashboardTab
            createSessionTab
            settingsTab
        }
    }
    
    
    // Tab Bar views
    private var dashboardTab: some View {
        Dashboard()
    }
    private var createSessionTab: some View {
        Color.aircastingGray
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
