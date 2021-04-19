//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI
import CoreData
import Firebase

struct MainTabBarView: View {
    let measurementUpdatingService: MeasurementUpdatingService
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @Environment(\.managedObjectContext) var managedObjectContext
    var body: some View {
        TabView {
            dashboardTab
            createSessionTab
            settingsTab
        }
        .onAppear {
            try! measurementUpdatingService.start()
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

    #warning("TODO: Change starting view")
    private var createSessionTab: some View {
        ChooseSessionTypeView(sessionContext: CreateSessionContext(createSessionService: CreateSessionAPIService(authorisationService: userAuthenticationSession), managedObjectContext: managedObjectContext))
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

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabBarView(measurementUpdatingService: MeasurementUpdatingServiceMock())
            .environmentObject(UserAuthenticationSession())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }

    private class MeasurementUpdatingServiceMock: MeasurementUpdatingService {
        func start() throws {}
    }
}
#endif
