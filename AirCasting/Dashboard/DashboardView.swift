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
            
            let request = NSFetchRequest<Session>(entityName: "Session")
            
            switch selectedSection {
            case .fixed:
                request.predicate = NSPredicate(format: "type == %@", SessionType.fixed.rawValue)
            case .mobileActive:
                request.predicate = NSPredicate(format: "type == %@ AND status == %li", SessionType.mobile.rawValue, SessionStatus.RECORDING.rawValue)
            case .mobileDormant:
                request.predicate = NSPredicate(format: "type == %@ AND status == %li", SessionType.mobile.rawValue, SessionStatus.FINISHED.rawValue)
            case .following:
                request.predicate = NSPredicate(format: "followedAt != NULL")
            }
            request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
            do {
                try coreDataHook.setup(fetchRequest: request,
                                   context: context)
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
