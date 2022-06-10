//
//  SessionsListView.swift
//  
//
//  Created by lunar  on 09/06/2022.
//

import SwiftUI
import Resolver
import AirCastingStyling
import CoreData

struct SessionsListView: View {
    @FetchRequest<SensorThreshold>(sortDescriptors: [.init(key: "sensorName", ascending: true)]) private var thresholds
    @StateObject private var coreDataHook: CoreDataHook
    @Binding var isRefreshing: Bool
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    
    private let listCoordinateSpaceName = "listCoordinateSpace"
    private let selectedSection: SelectedSection

    init(selectedSection: SelectedSection, isRefreshing: Binding<Bool>, context: NSManagedObjectContext) {
        self.selectedSection = selectedSection
        _isRefreshing = .init(projectedValue: isRefreshing)
        _coreDataHook = .init(wrappedValue: .init(context: context))
    }
    
    var body: some View {
        VStack {
            if coreDataHook.sessions.isEmpty {
                emptySessionsView
            } else {
                sessionListView
            }
        }
        .onAppear { try! coreDataHook.setup(selectedSection: selectedSection) }
    }
    
    private var sessionListView: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("dashboard-background-thing")
            let thresholds = Array(self.thresholds)
            ScrollView {
                RefreshControl(coordinateSpace: .named(listCoordinateSpaceName), isRefreshing: $isRefreshing)
                LazyVStack(spacing: 8) {
                    ForEach(coreDataHook.sessions.filter { $0.uuid != "" && !$0.gotDeleted }, id: \.uuid) { session in
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
            .coordinateSpace(name: listCoordinateSpaceName)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(Color.aircastingGray.opacity(0.05))
    }
    
    private var emptySessionsView: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    RefreshControl(coordinateSpace: .named(listCoordinateSpaceName), isRefreshing: $isRefreshing)
                    if selectedSection == .mobileActive || selectedSection == .mobileDormant {
                        EmptyMobileDashboardViewMobile()
                            .frame(height: geometry.size.height)
                    } else {
                        EmptyFixedDashboardView()
                            .frame(height: geometry.size.height)
                    }
                }
            }
            .coordinateSpace(name: listCoordinateSpaceName)
            .background(Color.aliceBlue)
        }
    }
}
