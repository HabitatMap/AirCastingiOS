//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import CoreData
import CoreBluetooth
import SwiftUI
import Resolver

struct MainTabBarView: View {
    let measurementUpdatingService: MeasurementUpdatingService
    let urlProvider: BaseURLProvider
    let measurementStreamStorage: MeasurementStreamStorage
    @State var homeImage: String = HomeIcon.selected.string
    @State var settingsImage: String = SettingsIcon.unselected.string
    @State var plusImage: String = PlusIcon.unselected.string
    let sessionStoppableFactory: SessionStoppableFactory
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var userSettings: UserSettings
    @InjectedObject private var bluetoothManager: BluetoothManager
    let sessionSynchronizer: SessionSynchronizer
    @StateObject var tabSelection: TabBarSelection = TabBarSelection()
    @StateObject var selectedSection = SelectSection()
    @StateObject var emptyDashboardButtonTapped = EmptyDashboardButtonTapped()
    @StateObject var finishAndSyncButtonTapped = FinishAndSyncButtonTapped()
    @StateObject var sessionContext: CreateSessionContext
    @StateObject var coreDataHook: CoreDataHook
    let locationHandler: LocationHandler
    
    private var sessions: [SessionEntity] {
        coreDataHook.sessions
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TabView(selection: $tabSelection.selection) {
                dashboardTab
                createSessionTab
                settingsTab
            }
            Button {
                tabSelection.selection = .dashboard
                try! coreDataHook.setup(selectedSection: .mobileActive)
                if sessions.contains(where: { $0.isActive }) {
                    selectedSection.selectedSection = .mobileActive
                } else {
                    selectedSection.selectedSection = .following
                }
                try! coreDataHook.setup(selectedSection: selectedSection.selectedSection)
            } label: {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: UIScreen.main.bounds.width / 3, height: 60)
            }
            
        }
        .onAppear {
            UITabBar.appearance().backgroundColor = .systemBackground
            let appearance = UITabBarAppearance()
            appearance.backgroundImage = UIImage()
            appearance.shadowImage = UIImage.mainTabBarShadow
            UITabBar.appearance().standardAppearance = appearance
            measurementUpdatingService.start()
        }
        .onChange(of: tabSelection.selection, perform: { _ in
            tabSelection.selection == .dashboard ? (homeImage = HomeIcon.selected.string) : (homeImage = HomeIcon.unselected.string)
            tabSelection.selection == .settings ? (settingsImage = SettingsIcon.selected.string) : (settingsImage = SettingsIcon.unselected.string)
            tabSelection.selection == .createSession ? (plusImage = PlusIcon.selected.string) : (plusImage = PlusIcon.unselected.string)
            
        })
        .onChange(of: bluetoothManager.mobileSessionReconnected, perform: { _ in
            if bluetoothManager.mobileSessionReconnected {
                bluetoothManager.mobilePeripheralSessionManager.configureAB(userAuthenticationSession: userAuthenticationSession)
                bluetoothManager.mobileSessionReconnected.toggle()
            }
        })
        .environmentObject(selectedSection)
        .environmentObject(tabSelection)
        .environmentObject(emptyDashboardButtonTapped)
        .environmentObject(finishAndSyncButtonTapped)
    }
}

private extension MainTabBarView {
    // Tab Bar views
    private var dashboardTab: some View {
        NavigationView {
            DashboardView(coreDataHook: coreDataHook,
                          measurementStreamStorage: measurementStreamStorage,
                          sessionStoppableFactory: sessionStoppableFactory,
                          sessionSynchronizer: sessionSynchronizer,
                          urlProvider: urlProvider)
        }.navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(homeImage)
            }
            .tag(TabBarSelection.Tab.dashboard)
    }
    
    private var createSessionTab: some View {
        ChooseSessionTypeView(viewModel: ChooseSessionTypeViewModel(locationHandler: locationHandler,
                                                                    bluetoothHandler: DefaultBluetoothHandler(),
                                                                    userSettings: userSettings,
                                                                    sessionContext: sessionContext,
                                                                    urlProvider: urlProvider,
                                                                    bluetoothManagerState: bluetoothManager.centralManagerState),
                              sessionSynchronizer: sessionSynchronizer)
            .tabItem {
                Image(plusImage)
            }
            .tag(TabBarSelection.Tab.createSession)
    }
    
    private var settingsTab: some View {
        SettingsView(urlProvider: UserDefaultsBaseURLProvider(),
                     logoutController: DefaultLogoutController(userAuthenticationSession: userAuthenticationSession,
                                                               sessionStorage: SessionStorage(),
                                                               sessionSynchronizer: sessionSynchronizer),
                     viewModel: SettingsViewModelDefault(locationHandler: locationHandler,
                                                         bluetoothHandler: DefaultBluetoothHandler(),
                                                         sessionContext: CreateSessionContext()))
            .tabItem {
                Image(settingsImage)
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
    @Published var selectedSection = SelectedSection.following
}

class EmptyDashboardButtonTapped: ObservableObject {
    @Published var mobileWasTapped = false
}

class FinishAndSyncButtonTapped: ObservableObject {
    @Published var finishAndSyncButtonWasTapped = false
}

extension MainTabBarView {
    enum HomeIcon {
        case selected
        case unselected
        
        var string: String {
            switch self {
            case .selected: return Strings.MainTabBarView.homeBlueIcon
            case .unselected: return Strings.MainTabBarView.homeIcon
            }
        }
    }
    
    enum PlusIcon {
        case selected
        case unselected
        
        var string: String {
            switch self {
            case .selected: return Strings.MainTabBarView.plusBlueIcon
            case .unselected: return Strings.MainTabBarView.plusIcon
            }
        }
    }
    
    enum SettingsIcon {
        case selected
        case unselected
        
        var string: String {
            switch self {
            case .selected: return Strings.MainTabBarView.settingsBlueIcon
            case .unselected: return Strings.MainTabBarView.settingsIcon
            }
        }
    }
}

// extension that allows us to centre images in the tabView
extension UITabBarController {
    open override func viewWillLayoutSubviews() {
        let array = self.viewControllers
        for controller in array! {
            controller.tabBarItem.imageInsets = UIEdgeInsets(top: 6,
                                                             left: 0,
                                                             bottom: -6,
                                                             right: 0)
        }
    }
}
