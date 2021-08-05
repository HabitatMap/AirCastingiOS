//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import CoreData
import Firebase
import SwiftUI

struct MainTabBarView: View {
    let measurementUpdatingService: MeasurementUpdatingService
    let urlProvider: BaseURLProvider
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var persistenceController: PersistenceController
    @EnvironmentObject var microphoneManager: MicrophoneManager
    let sessionSynchronizer: SessionSynchronizer
    @StateObject var tabSelection: TabBarSelection = TabBarSelection()
    @StateObject var selectedSection = SelectSection()

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
        .environmentObject(persistenceController)
        .environmentObject(selectedSection)
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

    private var createSessionTab: some View {
        ChooseSessionTypeView(sessionContext: CreateSessionContext(), urlProvider: urlProvider)
            .tabItem {
                Image(systemName: "plus")
            }
            .tag(TabBarSelection.Tab.createSession)
    }

    private var settingsTab: some View {
        SettingsView(urlProvider: UserDefaultsBaseURLProvider(), logoutController: DefaultLogoutController(
                        userAuthenticationSession: userAuthenticationSession,
                        sessionStorage: SessionStorage(persistenceController: persistenceController),
                        microphoneManager: microphoneManager,
                        sessionSynchronizer: sessionSynchronizer))
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

class SelectSection: ObservableObject {
    @Published var selectedSection = SelectedSection.mobileActive
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    private static let persistenceController = PersistenceController(inMemory: true)

    static var previews: some View {
        MainTabBarView(measurementUpdatingService: MeasurementUpdatingServiceMock(), urlProvider: DummyURLProvider(), sessionSynchronizer: DummySessionSynchronizer())
            .environmentObject(UserAuthenticationSession())
            .environmentObject(BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage())))
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage(), sessionSynchronizer: DummySessionSynchronizer()))
            .environmentObject(PersistenceController())
            .environment(\.managedObjectContext, persistenceController.viewContext)
    }

    private class MeasurementUpdatingServiceMock: MeasurementUpdatingService {
        func start() throws {}
    }
}
#endif
