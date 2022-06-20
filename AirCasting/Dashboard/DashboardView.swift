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
    // TODO: - We can rethink the way how "Select Section" works and change it
    @EnvironmentObject var selectedSection_: SelectSection
    @EnvironmentObject var reorderButton: ReorderButton
    @EnvironmentObject var searchAndFollowButton: SearchAndFollowButton
    @State var isRefreshing: Bool = false
    @State var selectedSection: SelectedSection = .following
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var persistenceController: PersistenceController
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    
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
            // It seems that there is a bug in SwiftUI for when a view contains a ScrollView (AirSectionPickerView).
            // When user pops back to this view using navigation the `large` title is displayed incorrectly.
            // As a workaround I`ve put a 1px rectangle between ScrollView and top. It seems to be doing the trick.
            //
            // Bug report was filled with Apple
            PreventCollapseView()
            if reorderButton.reorderIsOn {
                followingReorderTab
                ReorderingDashboard(sessions: sessions,
                                    thresholds: Array(self.thresholds))
            } else {
                sessionTypePicker
                TabView(selection: $selectedSection) {
                    ForEach(SelectedSection.allCases, id: \.self) {
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
        .onChange(of: selectedSection, perform: { newValue in
            self.selectedSection_.selectedSection = newValue
        })
        .onChange(of: isRefreshing, perform: { newValue in
            guard newValue == true else { return }
            guard !sessionSynchronizer.syncInProgress.value else {
                onCurrentSyncEnd { isRefreshing = false }
                return
            }
            sessionSynchronizer.triggerSynchronization() { isRefreshing = false }
        })
        .onAppear() {
            try! coreDataHook.setup(selectedSection: self.selectedSection_.selectedSection)
            reorderButton.isHidden = false
            searchAndFollowButton.isHidden = false
        }
    }

    private var sessionTypePicker: some View {
        AirSectionPickerView(selection: self.$selectedSection)
            .padding(.leading)
            .background(
                ZStack(alignment: .bottom) {
                    Color.green
                        .frame(height: 3)
                        .shadow(color: Color.aircastingDarkGray.opacity(0.4),
                                radius: 6)
                        .padding(.horizontal, -30)
                    Color.white
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
                    .shadow(color: Color.aircastingDarkGray.opacity(0.4),
                            radius: 6)
                    .padding(.horizontal, -30)
                Color.white
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

@available(iOS, deprecated: 15, obsoleted: 15, message: "Please review if this is still needed")
struct PreventCollapseView: View {
    private var mostlyClear = Color(UIColor(white: 0.0, alpha: 0.0005))
    var body: some View {
        Rectangle()
            .fill(mostlyClear)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 1)
    }
}
