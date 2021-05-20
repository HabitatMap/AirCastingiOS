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
    @EnvironmentObject var persistenceController: PersistenceController
    @StateObject var tabSelection: TabBarSelection = TabBarSelection()

    var body: some View {
        TabView(selection: $tabSelection.selection) {
            dashboardTab
            createSessionTab
            settingsTab
        }
        .onAppear {
            try! measurementUpdatingService.start()
        }
        .environmentObject(tabSelection)
    }
}

private extension MainTabBarView {
    
    // Tab Bar views
    private var dashboardTab: some View {
        NavigationView {
            DashboardView(coreDataHook: CoreDataHook(context: persistenceController.viewContext))
        }
        .tabItem {
            Image(systemName: "house")
        }
        .tag(TabBarSelection.Tab.dashboard)
    }
    
    #warning("TODO: Change starting view")
    private var createSessionTab: some View {
        ChooseSessionTypeView(sessionContext: CreateSessionContext())
            .tabItem {
                Image(systemName: "plus")
            }
            .tag(TabBarSelection.Tab.createSession)
    }
    private var settingsTab: some View {
        SettingsView()
            .tabItem {
                Image(systemName: "gearshape")
            }
            .tag(TabBarSelection.Tab.settings)
    }
}

class TabBarSelection: ObservableObject {
    @Published var selection = Tab.dashboard
    
    enum Tab {
        case dashboard
        case createSession
        case settings
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    private static let persistenceController = PersistenceController(inMemory: true)

    static var previews: some View {
        MainTabBarView(measurementUpdatingService: MeasurementUpdatingServiceMock())
            .environmentObject(UserAuthenticationSession())
            .environmentObject(BluetoothManager())
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
            .environment(\.managedObjectContext, persistenceController.viewContext)
    }
    
    private class MeasurementUpdatingServiceMock: MeasurementUpdatingService {
        func start() throws {}
    }
}
#endif
