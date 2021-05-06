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
    @State private var selectedView = SelectedSection.following
    
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
}

#if DEBUG
struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
#endif
