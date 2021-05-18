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
    @Environment(\.managedObjectContext) var context
    @StateObject private var coreDataHook = CoreDataHook()
    
    var sessions: [Session] {
        coreDataHook.sessions
    }
    
    var body: some View {
        VStack {
            
            AirSectionPickerView(selection: $selectedSection)

            if sessions.isEmpty {
                EmptyDashboardView()
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 20) {
                        ForEach(sessions, id: \.uuid) { (session) in
                            SessionCellView(session: session)
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
            do {
                coreDataHook.context = context
                try coreDataHook.setup(selectedSection: selectedSection)
            } catch {
                Log.error("Trying to fetch sessions. Error: \(error)")
            }
        }
    }
}

#if DEBUG
struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
#endif
