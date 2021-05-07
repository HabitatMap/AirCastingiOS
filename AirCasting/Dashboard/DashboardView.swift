//
//  Dashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import SwiftUI

struct DashboardView: View {
    
    @FetchRequest<Session>(sortDescriptors: [NSSortDescriptor(key: "startTime",
                                                              ascending: false)]) var sessions
    @State private var selectedView = SelectedSection.mobileActive
    
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
    
    func displaySessions(sessions: [Session]) -> [Session] {
        switch selectedView {
        case SelectedSection.following:
            #warning("TODO: return followed sessions after adding follow funcionality")
            return []
        case SelectedSection.mobileActive:
            return []
        case SelectedSection.mobileDormant:
            return []
        case SelectedSection.fixed:
            return []
        default:
            return []
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
