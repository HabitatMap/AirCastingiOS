//
//  Dashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @State private var selectedSection = SelectedSection.mobileActive
    @StateObject var coreDataHook: CoreDataHook
    @FetchRequest<SensorThreshold>(sortDescriptors: [.init(key: "sensorName", ascending: true)]) var thresholds

    private var sessions: [SessionEntity] {
        coreDataHook.sessions
    }

    var body: some View {
        VStack {
            AirSectionPickerView(selection: $selectedSection)

            if sessions.isEmpty {
                EmptyDashboardView()
            } else {
                let thresholds = Array(self.thresholds)
                ScrollView(.vertical) {
                    LazyVStack(spacing: 20) {
                        ForEach(sessions, id: \.uuid) { (session) in
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
        .onChange(of: selectedSection) { selectedSection in
            try! coreDataHook.setup(selectedSection: selectedSection)
        }
        .onAppear {
            try! coreDataHook.setup(selectedSection: selectedSection)
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
