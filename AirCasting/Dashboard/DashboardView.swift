//
//  Dashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import CoreData
import SwiftUI

struct DashboardView: View {
    #warning("This hook fires too often - on any stream measurement added/changed. Should only fire when list changes.")
    @StateObject var coreDataHook: CoreDataHook
    @FetchRequest<SensorThreshold>(sortDescriptors: [.init(key: "sensorName", ascending: true)]) var thresholds
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject var averaging: AveragingService
    
    @State private var dragOffset = CGFloat.zero
    
    let measurementStreamStorage: MeasurementStreamStorage
    let sessionStoppableFactory: SessionStoppableFactory
    
    private var sessions: [SessionEntity] {
        coreDataHook.sessions
    }
    init(coreDataHook: CoreDataHook, measurementStreamStorage: MeasurementStreamStorage, sessionStoppableFactory: SessionStoppableFactory) {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.darkBlue)]
        _coreDataHook = StateObject(wrappedValue: coreDataHook)
        self.measurementStreamStorage = measurementStreamStorage
        self.sessionStoppableFactory = sessionStoppableFactory
    }

    var body: some View {
        VStack(spacing: 0) {
            // It seems that there is a bug in SwiftUI for when a view contains a ScrollView (AirSectionPickerView).
            // When user pops back to this view using navigation the `large` title is displayed incorrectly.
            // As a workaround I`ve put a 1px rectangle between ScrollView and top. It seems to be doing the trick.
            //
            // Bug report was filled with Apple
            PreventCollapseView()
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
            if sessions.isEmpty {
                if selectedSection.selectedSection == .mobileActive || selectedSection.selectedSection == .mobileDormant {
                    EmptyMobileDashboardViewMobile()
                } else {
                    EmptyFixedDashboardView()
                }
            } else {
                ZStack(alignment: .bottomTrailing) {
                    Image("dashboard-background-thing")
                    let thresholds = Array(self.thresholds)
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 8) {
                            ForEach(sessions.filter { $0.uuid != "" }, id: \.uuid) { session in
                                let followingSetter = MeasurementStreamStorageFollowingSettable(session: session, measurementStreamStorage: measurementStreamStorage)
                                let viewModel = SessionCartViewModel(followingSetter: followingSetter)
                                SessionCartView(session: session,
                                                sessionCartViewModel: viewModel,
                                                thresholds: thresholds,
                                                sessionStoppableFactory: sessionStoppableFactory,
                                                measurementStreamStorage: measurementStreamStorage)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .background(Color.aircastingGray.opacity(0.05))
            }
        }
        .navigationBarTitle(NSLocalizedString(Strings.DashboardView.dashboardText, comment: ""))
        .onChange(of: selectedSection.selectedSection) { selectedSection in
            self.selectedSection.selectedSection = selectedSection
            try! coreDataHook.setup(selectedSection: self.selectedSection.selectedSection)
        }
    }
    
    func showPreviousTab() {
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
    
    func showNextTab() {
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

#if DEBUG
struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(coreDataHook: CoreDataHook(context: PersistenceController(inMemory: true).viewContext), measurementStreamStorage: PreviewMeasurementStreamStorage(), sessionStoppableFactory: SessionStoppableFactoryDummy())
    }
}
#endif
