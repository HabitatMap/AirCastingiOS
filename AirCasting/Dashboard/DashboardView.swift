//
//  Dashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import CoreData
import SwiftUI

struct DashboardView: View {
    @StateObject var coreDataHook: CoreDataHook
    @FetchRequest<SensorThreshold>(sortDescriptors: [.init(key: "sensorName", ascending: true)]) var thresholds
    @EnvironmentObject var selectedSection: SelectSection
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
        VStack {
            // It seems that there is a bug in SwiftUI for when a view contains a ScrollView (AirSectionPickerView).
            // When user pops back to this view using navigation the `large` title is displayed incorrectly.
            // As a workaround I`ve put a 1px rectangle between ScrollView and top. It seems to be doing the trick.
            //
            // Bug report was filled with Apple
            PreventCollapseView()
            AirSectionPickerView(selection: self.$selectedSection.selectedSection)

            if sessions.isEmpty {
                EmptyDashboardView()
            } else {
                ZStack(alignment: .bottomTrailing) {
                    Image("dashboard-background-thing")
                    let thresholds = Array(self.thresholds)
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 20) {
                            ForEach(sessions, id: \.uuid) { session in
                                let followingSetter = MeasurementStreamStorageFollowingSettable(session: session, measurementStreamStorage: measurementStreamStorage)
                                let viewModel = SessionCartViewModel(followingSetter: followingSetter)
                                SessionCartView(session: session, sessionCartViewModel: viewModel, thresholds: thresholds, sessionStoppableFactory: sessionStoppableFactory)
                            }                        }
                    }
                }.padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.aircastingGray.opacity(0.05))
            }
        }
        .navigationBarTitle(NSLocalizedString("Dashboard", comment: ""))
        .onChange(of: selectedSection.selectedSection) { selectedSection in
            self.selectedSection.selectedSection = selectedSection
            try! coreDataHook.setup(selectedSection: self.selectedSection.selectedSection)
        }
        .onAppear {
            try! coreDataHook.setup(selectedSection: selectedSection.selectedSection)
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
