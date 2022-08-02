//
//  Dashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import CoreData
import SwiftUI
import AirCastingStyling
import Combine
import Resolver

struct DashboardView: View {
    @StateObject var coreDataHook: CoreDataHook
    @FetchRequest<SensorThreshold>(sortDescriptors: [.init(key: "sensorName", ascending: true)]) var thresholds
    @EnvironmentObject var selectedSection: SelectedSection
    @EnvironmentObject var reorderButton: ReorderButton
    @EnvironmentObject var searchAndFollowButton: SearchAndFollowButton
    @State var isRefreshing: Bool = false
    @State private var alert: AlertInfo?
    @InjectedObject private var userSettings: UserSettings
    @Injected private var networkChecker: NetworkChecker
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var persistenceController: PersistenceController

    private var sessions: [Sessionable] {
        coreDataHook.sessions
    }

    init(coreDataHook: CoreDataHook) {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.darkBlue)]
        _coreDataHook = StateObject(wrappedValue: coreDataHook)
    }

    var body: some View {
        VStack(spacing: 0) {
            customNavigationBar
                .alert(item: $alert, content: { $0.makeAlert() })
            if reorderButton.reorderIsOn {
                followingReorderTab
                ReorderingDashboard(sessions: sessions,
                                    thresholds: Array(self.thresholds))
            } else {
                sessionTypePicker
                TabView(selection: $selectedSection.section) {
                    ForEach(DashboardSection.allCases, id: \.self) {
                        SessionsListView(selectedSection: $0, isRefreshing: $isRefreshing, context: persistenceController.viewContext)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .fullScreenCover(isPresented: $searchAndFollowButton.searchIsOn) {
            CreatingSessionFlowRootView {
                SearchView(isSearchAndFollowLinkActive: $searchAndFollowButton.searchIsOn)
            }
        }
        .navigationBarTitle(Strings.DashboardView.dashboardText)
        .navigationBarHidden(true)
        .onChange(of: isRefreshing, perform: { newValue in
            guard newValue == true else { return }
            guard !sessionSynchronizer.syncInProgress.value else {
                onCurrentSyncEnd { isRefreshing = false }
                return
            }
            guard networkChecker.connectionAvailable else {
                alert = InAppAlerts.noNetworkSyncAlert()
                isRefreshing = false
                return
            }
            guard !userSettings.syncOnlyThroughWifi || networkChecker.isUsingWifi else {
                alert = InAppAlerts.noWifiNetworkSyncAlert()
                isRefreshing = false
                return
            }
            sessionSynchronizer.triggerSynchronization() { isRefreshing = false }
        })
        .onAppear() {
            try! coreDataHook.setup(selectedSection: self.selectedSection.section)
        }
    }

    private var customNavigationBar: some View {
        VStack {
            customSpacer
            HStack {
                Text(Strings.DashboardView.dashboardText)
                    .font(Fonts.navBarSystemFont)
                    .foregroundColor(Color.darkBlue)
                    .padding()
                    .offset(x: 0, y: 20)

                Spacer()
            }
            customSpacer
        }
        .background(Color.aircastingBackground.ignoresSafeArea())
    }

    private var customSpacer: some View {
        Rectangle()
            .fill(Color(UIColor.aircastingBackground))
            .frame(height: 6)
    }

    private var sessionTypePicker: some View {
        AirSectionPickerView(selection: self.$selectedSection.section)
            .padding(.leading)
            .background(
                ZStack(alignment: .bottom) {
                    Color.green
                        .frame(height: 3)
                        .shadow(color: Color.sectionPickerShadowColor,
                                radius: 6)
                        .padding(.horizontal, -30)
                    Color.aircastingBackground
                }
            )
            .zIndex(2)
    }

    private var followingReorderTab: some View {
        HStack {
            Button(Strings.DashboardView.following) {
            }
            .buttonStyle(PickerButtonStyle(isSelected: true))
            Spacer()
        }
        .padding(.horizontal)
        .background(
            ZStack(alignment: .bottom) {
                Color.green
                    .frame(height: 3)
                    .shadow(color: Color.sectionPickerShadowColor,
                            radius: 6)
                    .padding(.horizontal, -30)
                Color.aircastingBackground
            }
        )
        .zIndex(2)
    }

    private func onCurrentSyncEnd(_ completion: @escaping () -> Void) {
        guard sessionSynchronizer.syncInProgress.value else { completion(); return }
        var cancellable: AnyCancellable?
        cancellable = sessionSynchronizer.syncInProgress.sink { syncInProgress in
            guard !syncInProgress else { return }
            completion()
            cancellable?.cancel()
        }
    }
}
