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
    @State var homeImage: String = HomeIcon.selected.string
    @State var settingsImage: String = SettingsIcon.unselected.string
    @State var plusImage: String = PlusIcon.unselected.string
    let sessionStoppableFactory: SessionStoppableFactory
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @EnvironmentObject var persistenceController: PersistenceController
    @EnvironmentObject var microphoneManager: MicrophoneManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var bluetoothManager: BluetoothManager
    let sessionSynchronizer: SessionSynchronizer
    @StateObject var tabSelection: TabBarSelection = TabBarSelection()
    @StateObject var selectedSection = SelectSection()
    @StateObject var emptyDashboardButtonTapped = EmptyDashboardButtonTapped()
    @StateObject var sessionContext: CreateSessionContext
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
            tabSelection.selection == .dashboard ? (homeImage = HomeIcon.selected.string) : (homeImage = HomeIcon.unselected.string)
            tabSelection.selection == .settings ? (settingsImage = SettingsIcon.selected.string) : (settingsImage = SettingsIcon.unselected.string)
            tabSelection.selection == .createSession ? (plusImage = PlusIcon.selected.string) : (plusImage = PlusIcon.unselected.string)
            
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
                .toolbar {
                // The toolbar is used to provide left align title in the way android has
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Text(Strings.MainTabBarView.dashboardText)
                            .foregroundColor(.darkBlue)
                            .font(Fonts.boldTitle5)
                            .padding(.top)
                    }
                }
        }.navigationViewStyle(StackNavigationViewStyle())
        .tabItem {
            Image(homeImage)
        }
        .tag(TabBarSelection.Tab.dashboard)
    }

    private var createSessionTab: some View {
        ChooseSessionTypeView(viewModel: ChooseSessionTypeViewModel(locationHandler: locationHandler, bluetoothHandler: DefaultBluetoothHandler(bluetoothManager: bluetoothManager), userSettings: userSettings, sessionContext: sessionContext, urlProvider: urlProvider, bluetoothManager: bluetoothManager, bluetoothManagerState: bluetoothManager.centralManagerState))
            .tabItem {
                Image(plusImage)
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
    @Published var selectedSection = SelectedSection.mobileActive
}

class EmptyDashboardButtonTapped: ObservableObject {
    @Published var mobileWasTapped = false
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
