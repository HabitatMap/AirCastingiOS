//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import CoreData
import Firebase
import CoreBluetooth
import SwiftUI

struct MainTabBarView: View {
    let measurementUpdatingService: MeasurementUpdatingService
    let urlProvider: BaseURLProvider
    let measurementStreamStorage: MeasurementStreamStorage
    @State var dashboardImage: String = "bluehome"
    let sessionStoppableFactory: SessionStoppableFactory

    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var persistenceController: PersistenceController
    @EnvironmentObject var microphoneManager: MicrophoneManager
    @EnvironmentObject var userSettings: UserSettings
    let sessionSynchronizer: SessionSynchronizer
    @StateObject var tabSelection: TabBarSelection = TabBarSelection()
    @StateObject var selectedSection = SelectSection()
    @StateObject var emptyDashboardButtonTapped = EmptyDashboardButtonTapped()
    @StateObject var sessionContext: CreateSessionContext
    @EnvironmentObject var bluetoothManager: BluetoothManager
    let locationHandler: LocationHandler
    
    var body: some View {
        TabView(selection: $tabSelection.selection) {
            dashboardTab
            createSessionTab
            settingsTab
        }
        .onAppear {
            measurementUpdatingService.start()
        }
        .onChange(of: tabSelection.selection, perform: { _ in
            if tabSelection.selection == .dashboard {
                dashboardImage = "bluehome"
            } else {
                dashboardImage = "home"
            }
        })
        .environmentObject(tabSelection)
        .environmentObject(selectedSection)
        .environmentObject(emptyDashboardButtonTapped)
    }
}

private extension MainTabBarView {
    // Tab Bar views
    private var dashboardTab: some View {
        NavigationView {
            DashboardView(coreDataHook: CoreDataHook(context: persistenceController.viewContext), measurementStreamStorage: measurementStreamStorage, sessionStoppableFactory: sessionStoppableFactory)
        }
        .tabItem {
            Image(dashboardImage)
        }
        .tag(TabBarSelection.Tab.dashboard)
    }

    private var createSessionTab: some View {
        ChooseSessionTypeView(viewModel: ChooseSessionTypeViewModel(locationHandler: locationHandler, bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: bluetoothManager), userSettings: userSettings, sessionContext: sessionContext, urlProvider: urlProvider, bluetoothManager: bluetoothManager, bluetoothManagerState: bluetoothManager.centralManagerState))
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

class EmptyDashboardButtonTapped: ObservableObject {
    @Published var mobileWasTapped = false
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    private static let persistenceController = PersistenceController(inMemory: true)

    static var previews: some View {
        MainTabBarView(measurementUpdatingService: MeasurementUpdatingServiceMock(), urlProvider: DummyURLProvider(), measurementStreamStorage: PreviewMeasurementStreamStorage(), sessionStoppableFactory: SessionStoppableFactoryDummy(), sessionSynchronizer: DummySessionSynchronizer(), sessionContext: CreateSessionContext(), locationHandler: DummyDefaultLocationHandler())
            .environmentObject(UserAuthenticationSession())
            .environmentObject(BluetoothManager(mobilePeripheralSessionManager: MobilePeripheralSessionManager(measurementStreamStorage: PreviewMeasurementStreamStorage())))
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
            .environment(\.managedObjectContext, persistenceController.viewContext)
    }

    private class MeasurementUpdatingServiceMock: MeasurementUpdatingService {
        func start() {}
    }
}
#endif
