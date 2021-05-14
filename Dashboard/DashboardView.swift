//
//  Dashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import SwiftUI
import CoreData

struct DashboardView: View {
    
    @State private var selectedView = SelectedSection.mobileActive
    @Environment(\.managedObjectContext) var context
    var sessions: [Session] {
        sessionFor(section: selectedView)
    }
    
    var body: some View {
        VStack {
            
            AirSectionPickerView(selection: $selectedView)

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
        .navigationBarTitle("Dashboard")
    }
    
    func sessionFor(section: SelectedSection) -> [Session] {
        let request = NSFetchRequest<Session>(entityName: "Session")
        
        switch section {
        case .fixed:
            request.predicate = NSPredicate(format: "type == %@", SessionType.fixed.rawValue)
        case .mobileActive:
            request.predicate = NSPredicate(format: "type == %@ AND status == %li", SessionType.mobile.rawValue, SessionStatus.RECORDING.rawValue)
        case .mobileDormant:
            request.predicate = NSPredicate(format: "type == %@ AND status == %li", SessionType.mobile.rawValue, SessionStatus.FINISHED.rawValue)
        case .following:
            request.predicate = NSPredicate(format: "followedAt != NULL")
        default: break
        }
        let results = try! context.fetch(request)
        return results
    }
}

#if DEBUG
struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
#endif
