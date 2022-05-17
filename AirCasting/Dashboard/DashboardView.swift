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
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject var reorderButton: ReorderButton
    @EnvironmentObject var searchAndFollowButton: SearchAndFollowButton
    @State var isRefreshing: Bool = false
    @State var isSwipingLeft: Bool = false
    @Injected private var sessionSynchronizer: SessionSynchronizer

    private let dashboardCoordinateSpaceName = "dashboardCoordinateSpace"

    private var sessions: [SessionEntity] {
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
                followingTab
                ReorderingDashboard(sessions: sessions, thresholds: Array(self.thresholds))
            } else {
                sessionTypePicker
                if sessions.isEmpty {
                    Group {
                        if selectedSection.selectedSection == .following {
                            emptyFollowingSessionsView
                        } else if selectedSection.selectedSection == .mobileActive {
                            emptyMobileActiveSessionsView
                        } else if selectedSection.selectedSection == .mobileDormant {
                            emptyMobileDormantSessionsView
                        } else if selectedSection.selectedSection == .fixed {
                            emptyFixedSessionsView
                        }
                    }
                    .transition(AnyTransition.asymmetric(insertion: .move(edge: isSwipingLeft ? .trailing : .leading), removal: .move(edge: isSwipingLeft ? .leading : .trailing)))
                } else {
                    Group {
                        if selectedSection.selectedSection == .following {
                            followingSessionListView
                        } else if selectedSection.selectedSection == .mobileActive {
                            mobileActiveSessionListView
                        } else if selectedSection.selectedSection == .mobileDormant {
                            mobileDormantSessionListView
                        } else if selectedSection.selectedSection == .fixed {
                            fixedSessionListView
                        }
                    }
                    .transition(AnyTransition.asymmetric(insertion: .move(edge: isSwipingLeft ? .trailing : .leading), removal: .move(edge: isSwipingLeft ? .leading : .trailing)))
                }
            }
        }
        .highPriorityGesture(DragGesture().onEnded({
            self.handleSwipe(translation: $0.translation.width)
        }))
        .animation(.default)
        .fullScreenCover(isPresented: $searchAndFollowButton.searchIsOn) {
            CreatingSessionFlowRootView {
                SearchView(isSearchAndFollowLinkActive: $searchAndFollowButton.searchIsOn)
            }
        }
        .navigationBarTitle(Strings.DashboardView.dashboardText)
        .onChange(of: selectedSection.selectedSection) { selectedSection in
            self.selectedSection.selectedSection = selectedSection
            try! coreDataHook.setup(selectedSection: self.selectedSection.selectedSection)
        }
        .onChange(of: isRefreshing, perform: { newValue in
            guard newValue == true else { return }
            guard !sessionSynchronizer.syncInProgress.value else {
                onCurrentSyncEnd { isRefreshing = false }
                return
            }
            sessionSynchronizer.triggerSynchronization() { isRefreshing = false }
        })
        .onAppear() {
            try! coreDataHook.setup(selectedSection: self.selectedSection.selectedSection)
            reorderButton.isHidden = false
            searchAndFollowButton.isHidden = false
        }
    }

    private var sessionTypePicker: some View {
        AirSectionPickerView(selection: self.$selectedSection.selectedSection)
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

    private var followingTab: some View {
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

    private var emptySessionsView: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    RefreshControl(coordinateSpace: .named(dashboardCoordinateSpaceName), isRefreshing: $isRefreshing)
                    if selectedSection.selectedSection == .mobileActive || selectedSection.selectedSection == .mobileDormant {
                        EmptyMobileDashboardViewMobile()
                            .frame(height: geometry.size.height)
                    } else {
                        EmptyFixedDashboardView()
                            .frame(height: geometry.size.height)
                    }
                }
            }
            .coordinateSpace(name: dashboardCoordinateSpaceName)
            .background(Color.aliceBlue)
        }
    }
    
    private var emptyFollowingSessionsView: some View { emptySessionsView }
    
    private var emptyMobileActiveSessionsView: some View { emptySessionsView }
    
    private var emptyMobileDormantSessionsView: some View { emptySessionsView }
    
    private var emptyFixedSessionsView: some View { emptySessionsView }

    private var sessionListView: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("dashboard-background-thing")
            let thresholds = Array(self.thresholds)
            ScrollView {
                RefreshControl(coordinateSpace: .named(dashboardCoordinateSpaceName), isRefreshing: $isRefreshing)
                LazyVStack(spacing: 8) {
                    ForEach(sessions.filter { $0.uuid != "" && !$0.gotDeleted }, id: \.uuid) { session in
                        let followingSetter = MeasurementStreamStorageFollowingSettable(session: session)
                        let viewModel = SessionCardViewModel(followingSetter: followingSetter)
                        SessionCardView(session: session,
                                        sessionCartViewModel: viewModel,
                                        thresholds: thresholds
                        )
                    }
                }
            }
            .coordinateSpace(name: dashboardCoordinateSpaceName)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(Color.aircastingGray.opacity(0.05))
    }
    
    private var fixedSessionListView: some View { sessionListView }
    
    private var followingSessionListView: some View { sessionListView }
    
    private var mobileActiveSessionListView: some View { sessionListView }
    
    private var mobileDormantSessionListView: some View { sessionListView }

    private func onCurrentSyncEnd(_ completion: @escaping () -> Void) {
        guard sessionSynchronizer.syncInProgress.value else { completion(); return }
        var cancellable: AnyCancellable?
        cancellable = sessionSynchronizer.syncInProgress.sink { syncInProgress in
            guard !syncInProgress else { return }
            completion()
            cancellable?.cancel()
        }
    }

    private func showPreviousTab() {
        switch selectedSection.selectedSection {
        case .following:
            break
        case .mobileActive:
            selectedSection.selectedSection = .following
        case .mobileDormant:
            selectedSection.selectedSection = .mobileActive
        case .fixed:
            selectedSection.selectedSection = .mobileDormant
        }
    }

    private func showNextTab() {
        switch selectedSection.selectedSection {
        case .following:
            selectedSection.selectedSection = .mobileActive
        case .mobileActive:
            selectedSection.selectedSection = .mobileDormant
        case .mobileDormant:
            selectedSection.selectedSection = .fixed
        case .fixed:
            break
        }
    }
    
    private func handleSwipe(translation: CGFloat) {
        let minDragTranslationForSwipe: CGFloat = 50
        if translation > minDragTranslationForSwipe {
            showPreviousTab()
            isSwipingLeft = false
        } else  if translation < -minDragTranslationForSwipe {
            showNextTab()
            isSwipingLeft = true
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
