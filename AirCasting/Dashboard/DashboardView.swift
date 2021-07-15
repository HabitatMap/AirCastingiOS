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

    private var sessions: [SessionEntity] {
        coreDataHook.sessions
    }
    
    init(coreDataHook: CoreDataHook) {
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.darkBlue)]
        _coreDataHook = StateObject(wrappedValue: coreDataHook)
    }

    var body: some View {
        VStack {
            AirSectionPickerView(selection: self.$selectedSection.selectedSection)
            if sessions.isEmpty {
                EmptyDashboardView()
            } else {
                let thresholds = Array(self.thresholds)
                ScrollView(.vertical) {
                    LazyVStack(spacing: 20) {
                        ForEach(sessions, id: \.uuid) { session in
                            SessionCartView(session: session, thresholds: thresholds)
                        }
                    }
                    .padding()
                }
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

#if DEBUG
struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(coreDataHook: CoreDataHook(context: PersistenceController(inMemory: true).viewContext))
    }
}
#endif
