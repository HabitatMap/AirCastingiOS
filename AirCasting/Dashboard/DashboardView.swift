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
    @State private var isSwipingLeft: Bool = false
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel

    private let dashboardCoordinateSpaceName = "dashboardCoordinateSpace"

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
                Group {
                    if selectedSection.selectedSection == .following {
                        followingTab
                            .transition(AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    } else if selectedSection.selectedSection == .mobileActive {
                        mobileActiveTab
                            .transition(AnyTransition.asymmetric(insertion: .move(edge: isSwipingLeft ? .trailing : .leading), removal: .move(edge: isSwipingLeft ? .leading : .trailing)))
                    } else if selectedSection.selectedSection == .mobileDormant {
                        mobileDormantTab
                            .transition(AnyTransition.asymmetric(insertion: .move(edge: isSwipingLeft ? .trailing : .leading), removal: .move(edge: isSwipingLeft ? .leading : .trailing)))
                    } else if selectedSection.selectedSection == .fixed {
                        fixedTab
                            .transition(AnyTransition.asymmetric(insertion: .move(edge: isSwipingLeft ? .trailing : .leading), removal: .move(edge: isSwipingLeft ? .leading : .trailing)))
                    }
                }
            }
        }
        .gesture(drag)
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
    
    private var mobileActiveTab: some View {
        Group {
            if sessions.isEmpty { emptySessionsView } else { sessionListView }
        }
    }
    
    private var followingTab: some View {
        Group {
            if sessions.isEmpty { emptySessionsView } else { sessionListView }
        }
    }
    
    private var mobileDormantTab: some View {
        Group {
            if sessions.isEmpty { emptySessionsView } else { sessionListView }
        }
    }
    
    private var fixedTab: some View {
        Group {
            if sessions.isEmpty { emptySessionsView } else { sessionListView }
        }
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
    
    private var sessionListView: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("dashboard-background-thing")
            let thresholds = Array(self.thresholds)
            ScrollView {
                RefreshControl(coordinateSpace: .named(dashboardCoordinateSpaceName), isRefreshing: $isRefreshing)
                LazyVStack(spacing: 8) {
                    ForEach(sessions.filter { $0.uuid != "" && !$0.gotDeleted }, id: \.uuid) { session in
                        if session.isExternal && featureFlagsViewModel.enabledFeatures.contains(.searchAndFollow) {
                            if let entity = session as? ExternalSessionEntity {
                                ExternalSessionCard(session: entity, thresholds: thresholds)
                            }
                        } else {
                            if let entity = session as? SessionEntity {
                                let followingSetter = MeasurementStreamStorageFollowingSettable(session: entity)
                                let viewModel = SessionCardViewModel(followingSetter: followingSetter)
                                SessionCardView(session: entity,
                                                sessionCartViewModel: viewModel,
                                                thresholds: thresholds
                                )
                            }
                        }
                    }
                }
            }
            .coordinateSpace(name: dashboardCoordinateSpaceName)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(Color.aircastingGray.opacity(0.05))
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
            Log.info("\(isSwipingLeft)")
        } else  if translation < -minDragTranslationForSwipe {
            showNextTab()
            isSwipingLeft = true
            Log.info("\(isSwipingLeft)")
        }
    }
    
    private var drag: some Gesture {
        DragGesture()
            .onEnded { value in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.handleSwipe(translation: value.translation.width)
                }
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
