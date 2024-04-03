//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import CoreData
import SwiftUI
import Resolver

struct MainTabBarView: View {
    @Injected private var measurementUpdatingService: MeasurementUpdatingService
    @StateObject var tabSelection: TabBarSelector = TabBarSelector()
    @StateObject var selectedSection = SelectedSection()
    @StateObject var reorderButton = ReorderButton()
    @StateObject var searchAndFollow = SearchAndFollowButton()
    @StateObject var emptyDashboardButtonTapped = EmptyDashboardButtonTapped()
    @StateObject var finishAndSyncButtonTapped = FinishAndSyncButtonTapped()
    @StateObject var exploreSessionsButton = ExploreSessionsButton()
    @StateObject var sessionContext: CreateSessionContext
    @StateObject var coreDataHook: CoreDataHook
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    @Environment(\.colorScheme) var colorScheme
    @State var measurementsDownloadingInProgress = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TabView(selection: .init(get: {
                tabSelection.selection
            }, set: { newSelection in
                tabSelection.update(to: newSelection)
            })) {
                dashboardTab
                createSessionTab
                settingsTab
            }
            Button {
                dashboardTapped()
            } label: {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: UIScreen.main.bounds.width / 3, height: 60)
            }
            
        }
        .onAppCameToForeground { performSessionsUpdate() }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = .aircastingBackground
            appearance.shadowImage = UIImage.mainTabBarShadow
            appearance.backgroundColor = .aircastingBackground
            UITabBar.appearance().standardAppearance = appearance
            performSessionsUpdate()
            measurementUpdatingService.start()
        }
        .environmentObject(selectedSection)
        .environmentObject(tabSelection)
        .environmentObject(emptyDashboardButtonTapped)
        .environmentObject(finishAndSyncButtonTapped)
        .environmentObject(exploreSessionsButton)
        .environmentObject(reorderButton)
        .environmentObject(searchAndFollow)
    }
    
    private func performSessionsUpdate() {
        measurementsDownloadingInProgress = true
        measurementUpdatingService.updateAllSessionsMeasurements() {
            DispatchQueue.main.async {
                measurementsDownloadingInProgress = false
            }
        }
    }
    
    private func dashboardTapped() {
        tabSelection.update(to: .dashboard)
        if !coreDataHook.getSessionsFor(section: .mobileActive).isEmpty {
            selectedSection.section = .mobileActive
        } else {
            selectedSection.section = .following
        }
        try! coreDataHook.setup(selectedSection: selectedSection.section)
    }
}

private extension MainTabBarView {
    private var dashboardTab: some View {
        NavigationView {
            DashboardView(coreDataHook: coreDataHook, measurementsDownloadingInProgress: $measurementsDownloadingInProgress)
        }.navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                createTabBarImage(tabSelection.getImageFor(.dashboard))
            }
            .tag(TabBarSelector.Tab.dashboard)
            .overlay(
                Group{
                    HStack {
                        if !searchAndFollow.isHidden && featureFlagsViewModel.enabledFeatures.contains(.searchAndFollow) && selectedSection.section == .following {
                            searchAndFollowButton
                        }
                        if reorderButton.reorderIsOn || (!reorderButton.isHidden && coreDataHook.sessions.count > 1 && selectedSection.section == .following) {
                            reorderingButton
                        }
                    }
                },
                alignment: .topTrailing
            )
    }
    
    private var createSessionTab: some View {
        ChooseSessionTypeView(sessionContext: sessionContext)
            .tabItem {
                createTabBarImage(tabSelection.getImageFor(.createSession))
            }
            .tag(TabBarSelector.Tab.createSession)
    }
    
    private var settingsTab: some View {
        SettingsView(sessionContext: sessionContext)
            .tabItem {
                createTabBarImage(tabSelection.getImageFor(.settings))
            }
            .tag(TabBarSelector.Tab.settings)
    }
    
    private var reorderingButton: some View {
        Group {
            if !reorderButton.reorderIsOn {
                Button {
                    reorderButton.reorderIsOn = true
                } label: {
                    Image("draggable-icon")
                        .renderingMode(.template)
                        .foregroundColor(colorScheme == .light ? .black : .aircastingGray)
                        .frame(width: 60, height: 60)
                        .imageScale(.large)
                }
                .offset(CGSize(width: 0.0, height: 42.0))
            } else {
                ZStack {
                    Rectangle()
                        .frame(width: 85, height: 35)
                        .cornerRadius(15)
                        .foregroundColor(.accentColor)
                        .opacity(0.1)
                    Button {
                        reorderButton.reorderIsOn = false
                    } label: {
                        Text(Strings.MainTabBarView.finished)
                            .font(Fonts.muliRegularHeading3)
                    }
                }
                .padding()
                .offset(CGSize(width: 0.0, height: 40.0))
            }
        }
    }
    
    private var searchAndFollowButton: some View {
        Group {
            Button {
                searchAndFollow.searchIsOn = true
            } label: {
                Image("SearchFollow")
                    .foregroundColor(Color.accentColor)
                    .frame(width: 60, height: 60)
                    .imageScale(.large)
            }
            .offset(CGSize(width: 0.0, height: 40.0))
        }
    }
    
    private func createTabBarImage(_ imageName: String) -> some View {
        Group {
            if colorScheme == .light {
                Image(imageName)
            } else {
                Image(imageName)
                    .renderingMode(.template)
                    .foregroundColor(.white)
            }
        }
    }
}

class SelectedSection: ObservableObject {
    @Published var section = DashboardSection.following
    @Published var mobileSessionWasFinished = false
}

enum DashboardSection: String, CaseIterable {
    case following = "Following"
    case mobileActive = "Mobile active"
    case mobileDormant = "Mobile dormant"
    case fixed = "Fixed"
    
    var localizedString: String {
        NSLocalizedString(rawValue, comment: "")
    }
    
    var allowsRefreshing: Bool {
        switch self {
        case .fixed, .mobileDormant: return true
        case .following, .mobileActive: return false
        }
    }
    
    var shouldShowMeasurementDownloadProgress: Bool {
        switch self {
        case .following: return true
        case .mobileDormant, .mobileActive, .fixed: return false
        }
    }
}

class EmptyDashboardButtonTapped: ObservableObject {
    @Published var mobileWasTapped = false
}

class ExploreSessionsButton: ObservableObject {
    @Published var exploreSessionsButtonTapped = false
}

class FinishAndSyncButtonTapped: ObservableObject {
    @Published var finishAndSyncButtonWasTapped = false
}

class ReorderButton: ObservableObject {
    @Published var reorderIsOn = false
    @Published var isHidden = false
    
    func setHidden(if isActive: Bool) {
        if isActive {
            isHidden = true
        } else {
            withAnimation {
                isHidden = false
            }
        }
    }
}

class SearchAndFollowButton: ObservableObject {
    @Published var searchIsOn = false
    @Published var isHidden = false
    
    func setHidden(if isActive: Bool) {
        if isActive {
            isHidden = true
        } else {
            withAnimation {
                isHidden = false
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
